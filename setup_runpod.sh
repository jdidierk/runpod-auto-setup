#!/bin/bash

# ----------------------
# CONFIGURATION AUTOMATIQUE POUR RUNPOD (ULTIMATE SD IMAGE)
# ----------------------

# Aller dans le dossier Stable Diffusion WebUI
cd /workspace/stable-diffusion-webui || exit

# Définir le jeton Hugging Face (REMPLACEZ "YOUR_HF_TOKEN" PAR VOTRE JETON)
HF_TOKEN="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"

# Définir le remote Rclone pour Google Drive
GDRIVE_REMOTE="gdrive:StableDiffusion-Images"
LOCAL_OUTPUTS="outputs"

# Vérifier et installer rclone si nécessaire
echo "🔍 Vérification de l'installation de rclone..."
if ! command -v rclone &> /dev/null; then
    echo "📦 Installation de rclone..."
    apt update && apt install -y rclone
else
    echo "✅ rclone est déjà installé."
fi

# Vérifier et configurer Rclone si nécessaire
mkdir -p ~/.config/rclone
if [ ! -f /workspace/rclone.conf ]; then
    echo "⚠️ Fichier rclone.conf introuvable. Création d'une configuration par défaut..."
    rclone config create gdrive drive scope drive
    cp $(rclone config file | awk '{print $NF}') /workspace/rclone.conf
fi

# Charger la configuration Rclone
cp /workspace/rclone.conf ~/.config/rclone/rclone.conf
    echo "✅ Configuration Rclone chargée."

# Télécharger le modèle ReV Animated depuis Hugging Face avec aria2c
echo "📥 Téléchargement du modèle ReV Animated..."
MODEL_URL="https://huggingface.co/danbrown/RevAnimated-v1-2-2/resolve/main/rev-animated-v1-2-2.safetensors"
MODEL_PATH="models/Stable-diffusion/rev-animated-v1-2-2.safetensors"

if [ ! -f "$MODEL_PATH" ]; then
    aria2c -x 16 -s 16 --header="Authorization: Bearer $HF_TOKEN" -o "$MODEL_PATH" "$MODEL_URL"
fi

if [ -f "$MODEL_PATH" ]; then
    echo "✅ Modèle téléchargé avec succès."
else
    echo "❌ Échec du téléchargement du modèle ReV Animated. Téléchargez-le manuellement."
fi

# Télécharger un VAE adapté avec git lfs
echo "📥 Téléchargement du VAE..."
VAE_DIR="models/VAE"
VAE_REPO="https://huggingface.co/stabilityai/sd-vae-ft-mse-original"
VAE_FILE="vae-ft-mse-840000-ema-pruned.safetensors"

if [ ! -f "$VAE_DIR/$VAE_FILE" ]; then
    mkdir -p "$VAE_DIR"
    cd "$VAE_DIR" || exit
    git lfs install
    git clone "$VAE_REPO" vae-repo
    cd vae-repo || exit
    git lfs pull --include="$VAE_FILE"
    mv "$VAE_FILE" ../
    cd ../
    rm -rf vae-repo
fi

if [ -f "$VAE_DIR/$VAE_FILE" ]; then
    echo "✅ VAE téléchargé avec succès."
else
    echo "❌ Échec du téléchargement du VAE. Téléchargez-le manuellement."
fi

# Télécharger le modèle depuis CivitAI
echo "📥 Téléchargement du modèle depuis CivitAI..."
CIVITAI_MODEL_DIR="models/Stable-diffusion"
mkdir -p "$CIVITAI_MODEL_DIR"
cd "$CIVITAI_MODEL_DIR" || exit
wget --content-disposition "https://civitai.com/api/download/models/119438?type=Model&format=SafeTensor&size=full&fp=fp16"

# Configuration des arguments de lancement
echo "⚙️ Configuration de lancement..."
echo "export COMMANDLINE_ARGS='--xformers --no-half-vae --theme dark'" >> ~/.bashrc
source ~/.bashrc

# Lancer AUTOMATIC1111
echo "🚀 Démarrage de l'interface WebUI..."
nohup python launch.py > webui.log 2>&1 &

# Automatiser la sauvegarde des images générées vers Google Drive toutes les 5 minutes
echo "🗂️ Configuration de la synchronisation avec Google Drive..."
while true; do
    echo "🔄 Synchronisation des images vers Google Drive..."
    rclone sync "$LOCAL_OUTPUTS" "$GDRIVE_REMOTE" --progress
    sleep 300  # Attente de 5 minutes
done &

# Définir un délai d'inactivité pour fermeture auto (ex: 1h = 3600s)
INACTIVITY_TIMEOUT=3600

echo "⏳ Suivi de l'activité..."
sleep $INACTIVITY_TIMEOUT

# Synchroniser une dernière fois avant d'éteindre le pod
echo "🔄 Dernière synchronisation des images avant arrêt..."
rclone sync "$LOCAL_OUTPUTS" "$GDRIVE_REMOTE" --progress

echo "🔻 Aucune activité détectée, arrêt du pod..."
poweroff
