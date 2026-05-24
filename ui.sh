#!/bin/bash
set -e
source /venv/main/bin/activate
WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR="${WORKSPACE}/ComfyUI"

echo "=== ComfyUI Gazik X-MODE 2026 ==="

APT_PACKAGES=(
    "aria2"
    "ffmpeg"
)

PIP_PACKAGES=()

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
    "https://github.com/ltdrdata/ComfyUI-Manager"
)

# ====================== ВСІ ТВОЇ МОДЕЛІ ======================
CLIP_MODELS=(
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/klip_vision.safetensors"
)
CLIPS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)
TEXT_ENCODERS=(
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/text_enc.safetensors"
)
UNET_MODELS=(
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
)
VAE_MODELS=(
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/vae.safetensors"
)
DETECTION_MODELS=(
    "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx"
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin"
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx"
)
LORAS=(
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/WanFun.reworked.safetensors"
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/light.safetensors"
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/light.safetensors"
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/WanPusa.safetensors"
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/wan.reworked.safetensors"
)
CLIP_VISION=(
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/klip_vision.safetensors"
)
DEFFUSION=(
    "https://huggingface.co/wdsfdsdf/OFMHUB/resolve/main/WanModel.safetensors"
)
# ============================================================

function provisioning_start() {
    echo ""
    echo "##############################################"
    echo "# Gazik X-MODE — чекаємо повного скачування #"
    echo "##############################################"
    echo ""

    provisioning_get_apt_packages
    provisioning_clone_comfyui
    provisioning_install_base_reqs
    provisioning_get_nodes
    provisioning_get_pip_packages

    echo "⏳ Починаємо скачування ВСІХ моделей... (це може зайняти від 5 до 40 хвилин)"
    echo ""

    provisioning_get_files "${COMFYUI_DIR}/models/clip" "${CLIP_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/clip_vision" "${CLIPS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/clip_vision" "${CLIP_VISION[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/text_encoders" "${TEXT_ENCODERS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/vae" "${VAE_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/diffusion_models" "${UNET_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/diffusion_models" "${DEFFUSION[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/detection" "${DETECTION_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/loras" "${LORAS[@]}"

    echo ""
    echo "✅ ВСІ моделі успішно завантажені!"
    echo "   ComfyUI зараз запуститься..."
    echo ""
}

# (всі інші функції залишаються такими ж, як у попередньому скрипті)
function provisioning_clone_comfyui() {
    if [[ ! -d "${COMFYUI_DIR}" ]]; then
        echo "Клонуємо ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
    else
        echo "Оновлюємо ComfyUI..."
        (cd "${COMFYUI_DIR}" && git pull --ff-only 2>/dev/null || git reset --hard origin/main)
    fi
    cd "${COMFYUI_DIR}"
}

function provisioning_install_base_reqs() {
    if [[ -f requirements.txt ]]; then
        echo "Встановлюємо base requirements..."
        pip install --no-cache-dir -r requirements.txt
    fi
}

function provisioning_get_apt_packages() {
    if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
        echo "Встановлюємо apt-пакети..."
        sudo apt update && sudo apt install -y "${APT_PACKAGES[@]}"
    fi
}

function provisioning_get_pip_packages() {
    if [[ ${#PIP_PACKAGES[@]} -gt 0 ]]; then
        pip install --no-cache-dir "${PIP_PACKAGES[@]}"
    fi
}

function provisioning_get_nodes() {
    mkdir -p "${COMFYUI_DIR}/custom_nodes"
    cd "${COMFYUI_DIR}/custom_nodes"
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        dir="${dir%.git}"
        path="./${dir}"
        if [[ -d "$path" ]]; then
            echo "Оновлюємо ноду: $dir"
            (cd "$path" && git pull --ff-only 2>/dev/null || { git fetch && git reset --hard origin/main; })
        else
            echo "Клонуємо ноду: $dir"
            git clone "$repo" "$path" --recursive --depth 1 || echo " [!] Clone failed: $repo"
        fi
        if [[ -f "$path/requirements.txt" ]]; then
            echo "Встановлюємо залежності $dir..."
            pip install --no-cache-dir -r "$path/requirements.txt" || echo " [!] pip failed for $dir"
        fi
    done
}

function provisioning_get_files() {
    if [[ $# -lt 2 ]]; then return; fi
    local dir="$1"
    shift
    mkdir -p "$dir"
    echo "📥 Завантажуємо ${#@} файлів → $dir (aria2c 16x)..."

    for url in "$@"; do
        echo "→ $url"
        local auth_header=""
        if [[ -n "$HF_TOKEN" && "$url" =~ huggingface\.co ]]; then
            auth_header="--header=Authorization: Bearer $HF_TOKEN"
        elif [[ -n "$CIVITAI_TOKEN" && "$url" =~ civitai\.com ]]; then
            auth_header="--header=Authorization: Bearer $CIVITAI_TOKEN"
        fi

        # ⚠️ Без || — якщо не скачається, скрипт зупиниться
        aria2c --console-log-level=error --summary-interval=0 \
               --continue --max-connection-per-server=16 --min-split-size=1M \
               --max-concurrent-downloads=16 --split=16 \
               $auth_header --dir="$dir" "$url"
    done
}

# Головний запуск
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

echo "=== Gazik запускає ComfyUI ==="
cd "${COMFYUI_DIR}"
python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --force-fp16 \
    --cuda-malloc \
    --preview-method auto
