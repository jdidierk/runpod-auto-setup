#!/bin/bash

# ----------------------
# CONFIGURATION AUTOMATIQUE POUR RUNPOD (ULTIMATE SD IMAGE)
# ----------------------

# Aller dans le dossier Stable Diffusion WebUI
cd /workspace/stable-diffusion-webui || exit

# Définir le jeton Hugging Face (REMPLACEZ "YOUR_HF_TOKEN" PAR VOTRE JETON)
HF_TOKEN="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"

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

# Configuration des arguments de lancement
echo "⚙️ Configuration de lancement..."
echo "export COMMANDLINE_ARGS='--xformers --no-half-vae --theme dark'" >> ~/.bashrc
source ~/.bashrc

# Lancer AUTOMATIC1111
echo "🚀 Démarrage de l'interface WebUI..."
nohup python launch.py > webui.log 2>&1 &

# Définir un délai d'inactivité pour fermeture auto (ex: 1h = 3600s)
INACTIVITY_TIMEOUT=3600

echo "⏳ Suivi de l'activité..."
sleep $INACTIVITY_TIMEOUT

echo "🔻 Aucune activité détectée, arrêt du pod..."
poweroff
