#!/bin/bash

# ----------------------
# CONFIGURATION AUTOMATIQUE POUR RUNPOD (ULTIMATE SD IMAGE)
# ----------------------

echo "📢 Démarrage du script de configuration..."

# Aller dans le dossier principal
cd /workspace || exit

# Créer le dossier Stable Diffusion WebUI s'il n'existe pas
mkdir -p stable-diffusion-webui
cd stable-diffusion-webui || exit

# Définir le jeton Hugging Face (REMPLACEZ "YOUR_HF_TOKEN" PAR VOTRE JETON)
HF_TOKEN="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"

# Définir le remote Rclone pour Google Drive
GDRIVE_REMOTE="gdrive:StableDiffusion-Outputs"
LOCAL_OUTPUTS="/workspace/stable-diffusion-webui/output"

# Vérifier et installer rclone si nécessaire
echo "🔍 Vérification de l'installation de rclone..."
if ! command -v rclone &> /dev/null; then
    echo "📦 Installation de rclone..."
    apt update && apt install -y rclone
else
    echo "✅ rclone est déjà installé."
fi

# Vérifier et configurer Rclone manuellement si nécessaire
mkdir -p ~/.config/rclone
if [ ! -f /workspace/rclone.conf ]; then
    echo "⚠️ Fichier rclone.conf introuvable. Configuration manuelle requise."
    echo "📢 Exécutez la commande suivante sur votre PC local :"
    echo "rclone authorize drive"
    echo "Puis copiez-collez le token généré ici :"
    read -p "Collez ici le token Rclone : " RCLONE_TOKEN
    echo "[gdrive]" > /workspace/rclone.conf
    echo "type = drive" >> /workspace/rclone.conf
    echo "token = $RCLONE_TOKEN" >> /workspace/rclone.conf
fi

# Charger la configuration Rclone
cp /workspace/rclone.conf ~/.config/rclone/rclone.conf
    echo "✅ Configuration Rclone chargée."

# Vérifier la configuration Rclone avant la synchronisation
if ! rclone lsd gdrive: &> /dev/null; then
    echo "⚠️ Problème d'authentification Rclone. Tentative de reconnexion..."
    rclone config reconnect gdrive:
fi

# Créer le dossier de sortie s'il n'existe pas
echo "📂 Vérification et création du dossier output..."
mkdir -p "$LOCAL_OUTPUTS"
chmod -R 777 "$LOCAL_OUTPUTS"

# Appliquer les réglages par défaut dans ui-config.json
echo "🔧 Configuration des paramètres par défaut..."
cat > /workspace/stable-diffusion-webui/ui-config.json <<EOL
{
    "txt2img/Sampling Steps": 45,
    "txt2img/Sampling method": "Euler a",
    "txt2img/Width": 1024,
    "txt2img/Height": 1536,
    "txt2img/CFG Scale": 11,
    "txt2img/Batch count": 4,
    "txt2img/Batch size": 1,
    "txt2img/Seed": -1,
    "txt2img/Hires fix": true,
    "txt2img/Hires upscale": 2,
    "txt2img/Upscaler": "R-ESRGAN 4x+ Anime6B",
    "txt2img/Denoising strength": 0.46
}
EOL

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

# Télécharger des modèles LORA
echo "📥 Téléchargement des modèles LORA..."
LORA_DIR="models/Lora"
mkdir -p "$LORA_DIR"
cd "$LORA_DIR" || exit

LORA_URLS=(
    "https://civitai.com/api/download/models/816096?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/35553?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/355491?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/339112?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/161744?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/212325?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/597456?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/576343?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/15481?type=Model&format=SafeTensor&size=full&fp=fp16"
)

for url in "${LORA_URLS[@]}"; do
    wget --content-disposition "$url"
done

cd /workspace/stable-diffusion-webui/models/Stable-diffusion/
wget --content-disposition "https://civitai.com/api/download/models/119438?type=Model&format=SafeTensor&size=full&fp=fp16"

# Démarrer AUTOMATIC1111
echo "🚀 Démarrage de l'interface WebUI..."
nohup python launch.py > webui.log 2>&1 &

# Automatiser la sauvegarde des images vers Google Drive toutes les 5 minutes
echo "🔄 Configuration de la synchronisation avec Google Drive..."
while true; do
    echo "🔄 Synchronisation des images vers Google Drive..."
    rclone copy "$LOCAL_OUTPUTS" "$GDRIVE_REMOTE" --progress --ignore-existing
    sleep 300  # Attente de 5 minutes
done &

# Définir un délai d'inactivité pour fermeture automatique
INACTIVITY_TIMEOUT=3600
echo "⏳ Suivi de l'activité..."
sleep $INACTIVITY_TIMEOUT

# Synchroniser une dernière fois avant d'éteindre le pod
echo "🔄 Dernière synchronisation des images avant arrêt..."
rclone copy "$LOCAL_OUTPUTS" "$GDRIVE_REMOTE" --progress --ignore-existing

echo "🔻 Aucune activité détectée, arrêt du pod..."
poweroff
