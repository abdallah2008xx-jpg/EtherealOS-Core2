#!/bin/bash
# سكريبت آمن للتشغيل المباشر (تخطي مشاكل مسار المجلد المشترك)
clear
echo "🚀 جاري الاتصال بخوادم EtherealOS GitHub..."

# تحميل التحديثات بعيداً عن مجلد الويندوز المشترك اللي بعمل مشاكل
rm -rf ~/ethereal-update 2>/dev/null
git clone https://github.com/abdallah2008xx-jpg/EtherealOS-Core.git ~/ethereal-update

# تشغيل واجهة التحديث اللي برمجناها
cd ~/ethereal-update
bash Ethereal-Update.sh

echo ""
echo "✅ اكتملت المهمة!"
read -n 1 -s -p "اضغط أي زر للخروج..."

