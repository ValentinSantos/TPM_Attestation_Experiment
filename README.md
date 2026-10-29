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

## 5. How to run the ECC experiment

Same flow as RSA, only the key type is ECC instead of RSA.

**On TPM-A:** create the ECC key in the TPM, sign `message.txt` and export the public key.

```bash
sudo ./scripts/Task_2/TPM-A-ECC.sh
scp message.txt ecc_signature.bin ecc-public.pem <user>@192.168.1.100:<TPM-B WORKDIR>/
```
Only the message, the signature and the public key are sent. The private key (`ecc.priv`) stays in TPM-A.

**On TPM-B:** load the public key and verify the signature. Run the script from the folder with the received files.

```bash
cd <TPM-B WORKDIR>
sudo ~/TPM_Attestation_Experiment/scripts/Task_2/TPM-B-ECC.sh
```

**Tamper test on TPM-B:** change the message and verify again.

```bash
echo "Fake tampered message" > message.txt
sudo ~/TPM_Attestation_Experiment/scripts/Task_2/TPM-B-ECC.sh
```

The ECC signature and public key are much smaller than the RSA ones. This is explained in the report.

## 6. How to run the PCR-bound signing experiment

**On TPM-A:** set the expected PCR 16 value, create the RSA key bound to it with a PCR policy and sign `message.txt`, then reset PCR 16 and try to sign again.

```bash
sudo ./scripts/Task_3/TPM-A-PCR.sh
scp message.txt pcr_signature.bin pcr_rsa-public.pem <user>@192.168.1.100:<TPM-B WORKDIR>/
```

**On TPM-B:** verify the signature made under the valid PCR state. The signature is saved in a plain format, so `-f rsassa` is needed.

```bash
cd <TPM-B WORKDIR>
sudo tpm2_loadexternal -G rsa -C o -u pcr_rsa-public.pem -c pcr_verify.ctx
sudo tpm2_verifysignature -c pcr_verify.ctx -g sha256 -f rsassa -m message.txt -s pcr_signature.bin
```

## 7. Assumptions and limitations

- Both TPMs are software TPMs from VirtualBox, not hardware TPMs, and both VMs run on the same computer.
- PCR 16 is extended manually, so the experiment shows how the PCR policy works, not a real measured boot state.
- TPM-B trusts the public key it gets over SCP. There is no EK certificate or quote, so TPM-B cannot prove the key is really inside a TPM.
- There is no nonce or timestamp, so an old valid signature could be replayed.



