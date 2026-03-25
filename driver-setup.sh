#!/bin/bash
# ==========================================================
# abdallahOS - Auto Hardware Detection & Driver Installer
# ==========================================================

clear
echo "╔════════════════════════════════════════════════════╗"
echo "║      ⚙️  abdallahOS Hardware & Driver Installer       ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "⏳ جاري فحص قطع الجهاز الخاصة بك..."
sleep 2

# Detect Graphics Card
GPU=$(lspci | grep -iE 'vga|3d|display')
echo -e "\n💻 [كرت الشاشة المكتشف]:\n  $GPU"

# Detect Network / Wi-Fi
NET=$(lspci | grep -iE 'network|ethernet')
echo -e "\n🌐 [كرت الشبكة المكتشف]:\n  $NET"

echo -e "\n🔍 تحليل التعريفات المطلوبة..."
sleep 2

PKGS="sys-kernel/linux-firmware"
GPU_DRIVER=""

if echo "$GPU" | grep -qi "nvidia"; then
    echo "  -> 🟢 كرت الشاشة من نوع NVIDIA. سيتم تثبيت: nvidia-drivers"
    PKGS="$PKGS x11-drivers/nvidia-drivers"
    GPU_DRIVER="nvidia"
elif echo "$GPU" | grep -qiE "amd|radeon"; then
    echo "  -> 🔴 كرت الشاشة من نوع AMD. سيتم تثبيت: xf86-video-amdgpu"
    PKGS="$PKGS x11-drivers/xf86-video-amdgpu"
    GPU_DRIVER="amdgpu"
elif echo "$GPU" | grep -qi "intel"; then
    echo "  -> 🔵 كرت الشاشة من نوع Intel. سيتم تثبيت: xf86-video-intel"
    PKGS="$PKGS x11-drivers/xf86-video-intel"
    GPU_DRIVER="intel"
else
    echo "  -> ⚙️ لم يتم التعرف على الكرت بشكل محدد، سيتم الاعتماد على تعريفات النواة الافتراضية."
fi

echo "  -> 📡 Installing linux-firmware and additional non-free drivers (Broadcom, Realtek, MediaTek)."
PKGS="$PKGS net-wireless/broadcom-sta net-wireless/b43-firmware net-wireless/rtw88-firmware net-wireless/rtw89-firmware net-wireless/mediatek-firmware net-wireless/iwl7260-firmware net-wireless/wireless-regdb"

echo ""
echo "====================================================="
read -p "هل تريد البدء في تحميل وتثبيت التعريفات الآن؟ (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 جاري التثبيت... الرجاء الانتظار، قد يستغرق هذا بعض الوقت."
    # We use emerge --getbinpkg to aggressively use binary packages if available, falling back to build.
    sudo emerge --getbinpkg -qv $PKGS

    if [ "$GPU_DRIVER" = "nvidia" ]; then
        echo "🔧 تفعيل إعدادات NVIDIA في Xorg..."
        sudo modprobe nvidia
    fi

    echo ""
    echo "✅ اكتمل تثبيت التعريفات بنجاح!"
    echo "🔄 يرجى إعادة تشغيل النظام لتطبيق التغييرات."
else
    echo "❌ تم إلغاء العملية."
fi

echo ""
read -p "اضغط أي مفتاح للإغلاق..."
