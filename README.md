# TPM_Attestation_Experiment

## 1. How to install the environment

Two Linux VMs in VirtualBox (7.0+): Kali as TPM-A, Ubuntu as TPM-B. In each VM, set **Settings → System → Motherboard → TPM: v2.0** and put both VMs on the same network with static IPs (TPM-A `192.168.1.99`, TPM-B `192.168.1.100`).

On both VMs:

```bash
sudo apt update && sudo apt install -y tpm2-tools git
git clone https://github.com/ValentinSantos/TPM_Attestation_Experiment.git
cd TPM_Attestation_Experiment && chmod +x scripts/*/*.sh
```

On TPM-B, also install the SSH server: `sudo apt install -y openssh-server`.

In each script, set `WORKDIR` to the directory that holds its files.

## 2. How to start TPM-A

```bash
sudo tpm2_getcap properties-fixed | grep -A2 TPM2_PT_FAMILY_INDICATOR
mkdir -p "$WORKDIR"
printf 'TPM exercise' > "$WORKDIR/message.txt"
```

## 3. How to start TPM-B

```bash
sudo tpm2_getcap properties-fixed | grep -A2 TPM2_PT_FAMILY_INDICATOR
sudo systemctl start ssh
mkdir -p "$WORKDIR"
```

## 4. How to run the RSA experiment

**On TPM-A:** create the RSA key in the TPM, sign `message.txt` and export the public key.

```bash
sudo ./scripts/Task_1/TPM-A-RSA.sh
scp message.txt signature.bin rsa-public.pem <user>@192.168.1.100:<TPM-B WORKDIR>/
```

Only the message, the signature and the public key are sent. The private key (`rsa.priv`) stays in TPM-A.

**On TPM-B:** load the public key and verify the signature.

```bash
sudo ./scripts/Task_1/TPM-B-RSA.sh
```

**Tamper test on TPM-B:** change the message and verify again.

```bash
echo "Fake tampered message" > message.txt
sudo ./scripts/Task_1/TPM-B-RSA.sh
```
