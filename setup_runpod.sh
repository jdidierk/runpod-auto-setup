#!/bin/bash

# ----------------------
# CONFIGURATION AUTOMATIQUE POUR RUNPOD (ULTIMATE SD IMAGE)
# ----------------------

# Aller dans le dossier Stable Diffusion WebUI
cd /workspace/stable-diffusion-webui || exit

# Télécharger le modèle ReV Animated depuis Hugging Face (Pluto)
echo "📥 Téléchargement du modèle ReV Animated..."
MODEL_URL="https://huggingface.co/pluto-research/revAnimated/resolve/main/revAnimated.safetensors"
MODEL_PATH="models/Stable-diffusion/revAnimated.safetensors"

if [ ! -f "$MODEL_PATH" ]; then
    aria2c -x 16 -s 16 -o "$MODEL_PATH" "$MODEL_URL"
fi

if [ -f "$MODEL_PATH" ]; then
    echo "✅ Modèle téléchargé avec succès."
else
    echo "❌ Échec du téléchargement du modèle ReV Animated. Téléchargez-le manuellement."
fi

# Télécharger un VAE adapté
echo "📥 Téléchargement du VAE..."
VAE_URL="https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
VAE_PATH="models/VAE/vae-ft-mse-840000-ema-pruned.safetensors"

if [ ! -f "$VAE_PATH" ]; then
    aria2c -x 16 -s 16 -o "$VAE_PATH" "$VAE_URL"
fi

if [ -f "$VAE_PATH" ]; then
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
