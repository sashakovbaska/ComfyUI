#!/bin/bash
set -e

source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR="${WORKSPACE}/ComfyUI"

echo "========================================="
echo "=== COMFYUI AUTO PROVISIONING (WAN) ==="
echo "========================================="

# ─────────────────────────────
# OPTIONAL PACKAGES
# ─────────────────────────────

APT_PACKAGES=()

PIP_PACKAGES=(
    "hf_transfer"
)

# ─────────────────────────────
# ENV
# ─────────────────────────────

export HF_HUB_ENABLE_HF_TRANSFER=1

# ─────────────────────────────
# CUSTOM NODES
# ─────────────────────────────

NODES=(
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/chflame163/ComfyUI_LayerStyle"
    "https://github.com/yolain/ComfyUI-Easy-Use"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/kijai/ComfyUI-segment-anything-2"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/fq393/ComfyUI-ZMG-Nodes"
    "https://github.com/kijai/ComfyUI-WanAnimatePreprocess"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/jnxmx/ComfyUI_HuggingFace_Downloader"
    "https://github.com/teskor-hub/NEW-UTILS.git"
)

# ─────────────────────────────
# MODELS
# ─────────────────────────────

# WAN DIFFUSION MODEL
DIFFUSION_MODELS=(
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_bf16.safetensors"
)

# CLIP VISION
CLIP_VISION_MODELS=(
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

# TEXT ENCODER
TEXT_ENCODERS=(
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

# VAE
VAE_MODELS=(
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

# DETECTION MODELS
DETECTION_MODELS=(
"https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx"
"https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin"
"https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx"
)

# LORAS
LORAS=(
"https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/WanFun.reworked.safetensors"
"https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/WanPusa.safetensors"
"https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/light.safetensors"
"https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/wan.reworked.safetensors"
)

# ─────────────────────────────
# START
# ─────────────────────────────

provisioning_start() {

    echo "########################################"
    echo "# STARTING COMFYUI INSTALLATION       #"
    echo "########################################"

    provisioning_get_apt_packages

    provisioning_clone_comfyui

    provisioning_install_base_requirements

    provisioning_get_nodes

    provisioning_get_pip_packages

    echo "========================================="
    echo "DOWNLOADING MODELS..."
    echo "========================================="

    provisioning_get_files \
        "${COMFYUI_DIR}/models/diffusion_models" \
        "${DIFFUSION_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/clip_vision" \
        "${CLIP_VISION_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/text_encoders" \
        "${TEXT_ENCODERS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/detection" \
        "${DETECTION_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/loras" \
        "${LORAS[@]}"

    echo "========================================="
    echo "INSTALLATION COMPLETE"
    echo "========================================="
}

# ─────────────────────────────
# COMFYUI
# ─────────────────────────────

provisioning_clone_comfyui() {

    if [[ ! -d "${COMFYUI_DIR}" ]]; then
        echo "Cloning ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
    fi

    cd "${COMFYUI_DIR}"

    echo "Updating ComfyUI..."

    git fetch origin
    git reset --hard origin/master
}

# ─────────────────────────────
# REQUIREMENTS
# ─────────────────────────────

provisioning_install_base_requirements() {

    echo "Installing ComfyUI requirements..."

    pip install --no-cache-dir -r "${COMFYUI_DIR}/requirements.txt"
}

provisioning_get_apt_packages() {

    if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
        sudo apt update
        sudo apt install -y "${APT_PACKAGES[@]}"
    fi
}

provisioning_get_pip_packages() {

    if [[ ${#PIP_PACKAGES[@]} -gt 0 ]]; then
        pip install --no-cache-dir "${PIP_PACKAGES[@]}"
    fi
}

# ─────────────────────────────
# CUSTOM NODES
# ─────────────────────────────

provisioning_get_nodes() {

    mkdir -p "${COMFYUI_DIR}/custom_nodes"

    cd "${COMFYUI_DIR}/custom_nodes"

    for repo in "${NODES[@]}"; do

        dir=$(basename "$repo" .git)

        path="./${dir}"

        if [[ -d "${path}" ]]; then

            echo "Updating node: ${dir}"

            (
                cd "${path}"

                git fetch origin

                git reset --hard origin/master || true

                git pull --rebase || true
            )

        else

            echo "Cloning node: ${dir}"

            git clone --recursive "${repo}" "${path}"
        fi

        if [[ -f "${path}/requirements.txt" ]]; then

            echo "Installing requirements for ${dir}"

            pip install --no-cache-dir -r "${path}/requirements.txt" || true
        fi
    done
}

# ─────────────────────────────
# MODEL DOWNLOADER
# ─────────────────────────────

provisioning_get_files() {

    local dir="$1"

    shift

    local files=("$@")

    mkdir -p "$dir"

    cd "$dir"

    for url in "${files[@]}"; do

        filename=$(basename "${url%%\?*}")

        echo "-----------------------------------------"
        echo "Downloading:"
        echo "${filename}"
        echo "-----------------------------------------"

        if [[ -f "${filename}" ]]; then
            echo "Already exists: ${filename}"
            continue
        fi

        wget \
            --content-disposition \
            --show-progress \
            -c \
            "$url"

        echo "DONE: ${filename}"
    done
}

# ─────────────────────────────
# RUN PROVISIONING
# ─────────────────────────────

if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

# ─────────────────────────────
# START COMFYUI
# ─────────────────────────────

echo "========================================="
echo "STARTING COMFYUI..."
echo "========================================="

cd "${COMFYUI_DIR}"

python main.py \
    --listen 0.0.0.0 \
    --port 8188
