#!/bin/bash
#
# Setup running of opal with CSR-2D-ML wake field calculation
#
set -eou pipefail

main() {
    declare run_d=${1:-}
    if [[ ! $run_d ]]; then
        echo "usage: $0 run_dir
You must supply a directory to create files and run mlopal in." 1>&2
        exit 1
    fi
    if [[ ! $run_d =~ ^/ ]]; then
        run_d=$PWD/$run_d
    fi
    if [[ -d $run_d ]]; then
        echo "$run_d already exists. Not overwriting.
Exiting." 1>&2
        exit 1
    fi
    mkdir "$run_d"
    cd "$run_d"
    declare m=rs_mlopal_model.pth
    curl -s -S -L -O '${RS_MLOPAL_FOSS_SERVER}'/"$m"
    cat > cvae.py <<EOF
import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from skimage import transform

_STEP = {'step': 0}
_DEBUG = False

NORMALIZATION = {'rho_max': {'mean': 699246912.0, 'std': 328316128.0},
 'rho': {'mean': 6207542.5, 'std': 30716538.0},
 'Ws': {'mean': -8533.6123046875, 'std': 114306.03125},
 'Wx': {'mean': 891.7451171875, 'std': 948.9319458007812},
 'Sx': {'mean': 0.0014085194561630487, 'std': 9.974500426324084e-05},
 'Sz': {'mean': 0.00014250849199015647, 'std': 6.964922795305029e-05},
 's': {'mean': 0.5315000414848328, 'std': 0.3065386712551117}}

class Encoder(nn.Module):
    def __init__(self):
        super(Encoder, self).__init__()

        self.encoding_dim = 16
        self.scalar_count = 4  # number of scalars given at forward
        num_conv = 7
        nfilters = 32
        kernel_sizes = [3, 7]
        pool_size = 2
        activation = nn.ReLU()

        #### CNN
        encoder_layers = [nn.Conv2d(1, nfilters, kernel_size=3, padding='same'), activation]
        for i in range(num_conv - 1):
            for kernel_size in kernel_sizes:
                encoder_layers += [nn.Conv2d(nfilters, nfilters, kernel_size, padding='same'), activation]
            encoder_layers += [nn.MaxPool2d((pool_size, pool_size)),]

        self.encoder = nn.Sequential(*encoder_layers)


        #### Linear
        linear = []
        linear += [nn.Flatten()]  # (1, 96)
        # VAE uses 2 * encoding_dim because we need to send equal sized arrays to mean and logvar
        linear += [nn.LazyLinear(self.encoding_dim), activation]
        self.flatten_encoder = nn.Sequential(*linear)


        linear = []
        linear += [nn.Flatten()]  # (1, 96)
        # VAE uses 2 * encoding_dim because we need to send equal sized arrays to mean and logvar
        linear += [nn.LazyLinear((self.encoding_dim  + self.scalar_count) * 2), activation]
        self.mean_and_logvar = nn.Sequential(*linear)


    def forward(self, input_image, position, x_beam_span, z_beam_span, rho_max):
        x_encoded = self.encoder(input_image)
        # print(f"{x_encoded.shape=}")
        # print(f"{position.shape=}")
        x_encoded_flat = self.flatten_encoder(x_encoded)
        mean_and_logvar = self.mean_and_logvar(torch.cat(
                                    (x_encoded_flat, position, x_beam_span, z_beam_span, rho_max),
                                    dim=1)
                          )
        mean = mean_and_logvar[:, :(self.encoding_dim + self.scalar_count)]
        logvar = mean_and_logvar[:, (self.encoding_dim + self.scalar_count):]

        return mean, logvar


class Decoder(nn.Module):
    def __init__(self):
        super(Decoder, self).__init__()

        # TODO: small_dim_power2 shared with Latent
        small_dim_power2 = 4
        num_deconv = 7 - small_dim_power2

        nfilters = 32
        kernel_sizes = [3, 7]
        pool_size = 2
        activation = nn.ReLU()

        #### CNN
        decoder_layers = [
            nn.ConvTranspose2d(1, nfilters, kernel_size=3, padding=(1, 1)),
            nn.ReLU(),
            nn.ConvTranspose2d(nfilters, nfilters, kernel_size=7, padding=(3, 3)),
            nn.ReLU(),
            nn.Upsample(scale_factor=pool_size),

            nn.ConvTranspose2d(nfilters, nfilters, kernel_size=3, padding=(1, 1)),
            nn.ReLU(),
            nn.ConvTranspose2d(nfilters, nfilters, kernel_size=7, padding=(3 , 3)), ###
            nn.ReLU(),
            nn.Upsample(scale_factor=pool_size),

            nn.ConvTranspose2d(nfilters, nfilters, kernel_size=3, padding=(1, 1)),
            nn.ReLU(),
            nn.ConvTranspose2d(nfilters, nfilters, kernel_size=7, padding=(3, 3)),
            nn.ReLU(),
            nn.Upsample(scale_factor=pool_size),

        ]

        decoder_layers += [nn.Conv2d(nfilters, 2, kernel_size=1, padding='same')]

        self.decoder = nn.Sequential(*decoder_layers)

    def forward(self, x):
        x_decoded = self.decoder(x)

        return x_decoded


class LinearLatent(nn.Module):
    def __init__(self):
        super(LinearLatent, self).__init__()
        # TODO: small_dim_power2, nfilters and pool_size are shared parameters between encoder and linear latent now
        nfilters = 32
        pool_size = 2
        num_conv = 7
        self.small_dim_power2 = 4

        num_dense = 2
        self.small_dim_power2 = 4
        num_units = 400
        activation = nn.ReLU()

        dense_layers = []
        for i in range(num_dense):
            dense_layers.extend((nn.LazyLinear(num_units), activation))
        dense_layers.extend((nn.LazyLinear(2**(2*self.small_dim_power2+1)), activation))
        self.intermediate = nn.Sequential(*dense_layers)

    def forward(self, encoder_output):
        x = self.intermediate(encoder_output)
        x = x.reshape((-1,1, 2**(self.small_dim_power2+1), 2**self.small_dim_power2))

        return x


class CSR2DVAE(nn.Module):
    def __init__(self):
        super(CSR2DVAE, self).__init__()

        self.encoder = Encoder()
        self.latent = LinearLatent()
        self.decoder = Decoder()

    def reparameterize(self, mu, logvar):
        std = torch.exp(0.5*logvar)
        eps = torch.randn_like(std)
        if self.training:
            return mu + eps*std
        else:
            return mu

    def forward(self, input_image, position, x_beam_span, z_beam_span, rho_max):

        mean, logvar = self.encoder(input_image,  position, x_beam_span, z_beam_span, rho_max)
        z = self.reparameterize(mean, logvar)
        x = self.latent(z)
        x = self.decoder(x)

        return x, mean, logvar



def loss_function(wakes_reconstructed, wake_s, wake_x, mean, logvar):
    MSE = nn.MSELoss(reduction='sum')(wakes_reconstructed, torch.concat((wake_s, wake_x), axis=1))

    KLD = -0.5 * torch.sum(1 + logvar - mean.pow(2) - logvar.exp())

    return MSE, KLD


MODEL_PATH = '$run_d/$m'
CSR2D_MODEL = CSR2DVAE()
CSR2D_MODEL.load_state_dict(torch.load(MODEL_PATH))
CSR2D_MODEL.eval()

def call_model(lambda_distribution, scalars, device='cpu:0'):
    # lambda_distribution  =lambda_distribution.T
    if _DEBUG:
        log_file = open("model.log", 'a')

    if _DEBUG:
        np.save("lambda_start_kick-{}.npy".format(_STEP['step']), lambda_distribution)

    NZ0, NX0 = lambda_distribution.shape[-2:]
    NZ, NX = 256, 128

    lambda_m, lambda_s = NORMALIZATION['rho']['mean'], NORMALIZATION['rho']['std']
    lambda_rescaled = torch.Tensor(
        transform.resize(lambda_distribution, (NZ, NX)).reshape([1, 1, NZ, NX])
    )
    lambda_rescaled = (lambda_rescaled - lambda_m) / lambda_s

    if _DEBUG:
        np.save("lambda_rescaled_kick-{}.npy".format(_STEP['step']), lambda_rescaled)

    for k, v in scalars.items():
        scalars[k] = torch.Tensor([v]).reshape([-1, 1])
        if NORMALIZATION.get(k):
            m, s = NORMALIZATION[k]['mean'], NORMALIZATION[k]['std']
            if _DEBUG:
                log_file.write(f"{k}: mean={m}, std={s}\n")
            scalars[k] = (scalars[k] - m) / s

    if _DEBUG:
        log_file.write("model.call_model::scalar values\n")
        for k, v in scalars.items():
            log_file.write(f" {k} = {v}\n")

    wakes, _, _ = CSR2D_MODEL(lambda_rescaled,
                        position=scalars['s'],
                        x_beam_span=scalars['Sx'],
                        z_beam_span=scalars['Sz'],
                        rho_max=scalars['rho_max'])


    wake_s_m, wake_s_s = NORMALIZATION['Ws']['mean'], NORMALIZATION['Ws']['std']
    wake_s = wakes[0, 0, :, :] * wake_s_s + wake_s_m
    # Default is to use grid for wake that is +1 from charge deposition grid
    wake_s = transform.resize(wake_s.cpu().detach().numpy(), (NZ0 + 1, NX0 + 1))
    wake_x_m, wake_x_s = NORMALIZATION['Wx']['mean'], NORMALIZATION['Wx']['std']
    wake_x = wakes[0, 1, :, :] * wake_x_s + wake_x_m
    # Default is to use grid for wake that is +1 from charge deposition grid
    wake_x = transform.resize(wake_x.cpu().detach().numpy(), (NZ0 + 1, NX0 + 1))

    _STEP['step'] += 1
    return wake_s, wake_x
EOF

    declare p=$run_d/get_wake.py
    cat > "$p" <<'EOF'
#!/usr/bin/env python
#
# Calculate the wake field from 2D lambda distribution
#
import cvae
import numpy as np
import sys

def main(data_file):
    data = _read_data(data_file)
    ws, wx = _get_wake(data)
    _write_wake(ws, wx)


def _get_wake(data):
    return cvae.call_model(
        data["lambda_distribution"],
        {k:v for k, v in data.items() if k != 'lambda_distribution'},
)


def _read_data(data_file):
    data = np.fromfile(data_file, dtype=np.float64)
    rows = int(data[0])
    cols = int(data[1])
    num_elements = rows * cols
    return {
        "lambda_distribution": data[2 : num_elements + 2].reshape(rows, cols),
        "bend_radius": data[num_elements + 2],
        "bend_angle": data[num_elements + 3],
        "x_beam_span": data[num_elements + 4],
        "z_beam_span": data[num_elements + 5],
    }


def _write_wake(wake_s, wake_x):
    with open("wake.bin", "wb") as f:
        wake_s.tofile(f)
        wake_x.tofile(f)


if __name__ == "__main__":
    main(sys.argv[1])
EOF

    declare i=opal.in
    echo "Creating example opal.in. Edit to suit your simulation needs"
    cat > "$i" <<EOF
// Example OPAL input file using CSR-2D-ML wake calculation
Title, string="CSR Bend Drift";

REAL beam_bunch_charge = 1e-09;
REAL bend_angle = 0.5235987755982988;
REAL bend_energy = 6.50762633;
REAL bend_length = 0.129409522551;
REAL gamma = (bend_energy * 1e-3 + emass) / emass;
REAL beta = sqrt(1 - (1/pow(gamma, 2)));
REAL csr_sg_nleft = 5.0;
REAL csr_sg_nright = 4.0;
REAL csr_sg_polyorder = 4.0;
REAL drift_before_bend = 0.1;
REAL fs_sc1_x_bins = 8.0;
REAL fs_sc1_y_bins = 8.0;
REAL fs_sc1_z_bins = 64.0;
REAL gambet = gamma * beta;
REAL number_of_particles = 5000.0;
REAL p0 = gamma * beta * emass;
REAL ps_dump_frequency = 20.0;
REAL rf_frequency = 100000000.0;
REAL rf_wavelength = clight / rf_frequency;
REAL stat_dump_frequency = 1.0;
REAL time_step_1 = 4.37345628028939e-12;


"OP1": option,autophase=1.0,csrdump=true,info=false,psdumpfreq=PS_DUMP_FREQUENCY,statdumpfreq=STAT_DUMP_FREQUENCY,version=10900.0;
"SG_FILTER": filter,nleft=CSR_SG_NLEFT,npoints=CSR_SG_NLEFT + CSR_SG_NRIGHT + 1,nright=CSR_SG_NRIGHT,polyorder=CSR_SG_POLYORDER,type="SAVITZKY-GOLAY";
"CSR_2D_ML_WAKE": wake,type="2D-CSR-ML",py_filepath="$p",nbinx=8, nbinz=10;

"D1": DRIFT,l=drift_before_bend;
"D2": DRIFT,l=0.4,wakef=CSR_2D_ML_WAKE;
"S1": SBEND,angle=bend_angle,designenergy=bend_energy,e1=0.08726646259971647,e2=0.08726646259971647,gap=0.02,l=bend_length,wakef=CSR_2D_ML_WAKE;

"D1#0": "D1",elemedge=0;
"S1#0": "S1",elemedge=0.1;
"D2#0": "D2",elemedge=0.229409522551;
BL1: LINE=("D1#0","S1#0","D2#0");


"FS_SC1": fieldsolver,fstype="NONE",mt=FS_SC1_Z_BINS,mx=FS_SC1_X_BINS,my=FS_SC1_Y_BINS,parfftx=true,parffty=true;
"DI1": distribution,sigmapx=0.0025,sigmapy=0.0025,sigmapz=0.01,sigmax=0.00025,sigmay=0.00025,sigmaz=5e-05,type="GAUSS";
"BEAM1": beam,bcurrent=BEAM_BUNCH_CHARGE * RF_FREQUENCY,bfreq=RF_FREQUENCY * 1e-6,npart=NUMBER_OF_PARTICLES,particle="ELECTRON",pc=P0;
"TR1": track,beam=beam1,dt=TIME_STEP_1,line=BL1,maxsteps=2000.0,zstop=0.6316;
 run, beam=beam1,distribution=DI1,fieldsolver=FS_SC1,method="PARALLEL-T";
 endtrack;
EOF

    echo "To run mlopal:
mlopal $i"
}

main "$@"
