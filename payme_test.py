import requests
import json

PAYME_ID = "69579c19129dca1effbfd875"
PAYME_KEY = "b3eF5x7N&6&@E@5#SM5yZaBgoB9Sc5uybyuo"
BASE_URL = "https://checkout.paycom.uz/api"  # Production (test ishlamadi)


def call_api(method, params, use_key=False):
    auth = f"{PAYME_ID}:{PAYME_KEY}" if use_key else PAYME_ID
    headers = {
        "X-Auth": auth,
        "Content-Type": "application/json"
    }
    payload = {"id": 1, "method": method, "params": params}
    resp = requests.post(BASE_URL, json=payload, headers=headers)
    data = resp.json()

    if "error" in data:
        print(f"\n❌ Xato [{data['error']['code']}]: {data['error']['message']}")
        print(f"   data: {data['error'].get('data', '')}")
        return None
    return data.get("result")


def main():
    print("=" * 55)
    print("   🟢 PAYME Subscribe API — Real To'lov Testi")
    print("=" * 55)

    # --- Karta ma'lumotlari ---
    print("\n💳 KARTA MA'LUMOTLARI")
    card_number = input("  Karta raqami (bo'shliqsiz): ").replace(" ", "")
    card_expire = input("  Amal qilish muddati (MMYY, masalan 0328): ").strip()

    amount_uzs = input("\n💰 To'lov summasi (so'mda, masalan 1000): ").strip()
    amount_tiyin = int(amount_uzs) * 100
    order_id = input("📦 Order ID (masalan 12345): ").strip()

    # --- STEP 1: Token olish ---
    print("\n─────────────────────────────────────────────")
    print("🔄 STEP 1: Karta tokenini yaratish...")
    result = call_api("cards.create", {
        "card": {
            "number": card_number,
            "expire": card_expire
        },
        "save": False
    })

    if not result:
        print("❌ Token yaratib bo'lmadi. To'xtatildi.")
        return

    token = result["card"]["token"]
    masked = result["card"]["number"]
    print(f"✅ Token olindi!")
    print(f"   Karta: {masked}")
    print(f"   Token: {token[:30]}...")

    # --- STEP 2: SMS yuborish ---
    print("\n─────────────────────────────────────────────")
    print("📲 STEP 2: SMS kod yuborilmoqda...")
    result = call_api("cards.get_verify_code", {"token": token})

    if not result:
        print("❌ SMS yuborilib bo'lmadi.")
        return

    phone = result.get("phone", "???")
    print(f"✅ SMS yuborildi → {phone}")

    # --- STEP 3: SMS tasdiqlash ---
    print("\n─────────────────────────────────────────────")
    sms_code = input("🔑 STEP 3: SMS kodni kiriting: ").strip()

    result = call_api("cards.verify", {
        "token": token,
        "code": sms_code
    })

    if not result:
        print("❌ Tasdiqlash muvaffaqiyatsiz.")
        return

    print(f"   Server javobi: {json.dumps(result, indent=2, ensure_ascii=False)}")

    verified = result["card"].get("verified", False)
    recurrent = result["card"].get("recurrent", False)
    print(f"   verified={verified}, recurrent={recurrent}")

    # Ba'zi kassalarda verified=False bo'ladi lekin to'lov ishlaydi
    print("✅ Karta qayta ishlandi — davom etamiz...")

    # --- STEP 4: Chek yaratish ---
    print("\n─────────────────────────────────────────────")
    print(f"🧾 STEP 4: Chek yaratilmoqda ({amount_uzs} so'm)...")
    result = call_api("receipts.create", {
        "amount": amount_tiyin,
        "account": {"order_id": order_id},
        "description": f"Test to'lov - order {order_id}"
    }, use_key=True)

    if not result:
        print("❌ Chek yaratib bo'lmadi.")
        return

    receipt_id = result["receipt"]["_id"]
    state = result["receipt"]["state"]
    print(f"✅ Chek yaratildi!")
    print(f"   Receipt ID: {receipt_id}")
    print(f"   Holat: {state} (0=yaratildi)")

    # --- Tasdiqlash ---
    print("\n─────────────────────────────────────────────")
    confirm = input(f"⚠️  {amount_uzs} so'm yechiladi. Davom etasizmi? (ha/yo'q): ").strip().lower()
    if confirm not in ("ha", "h", "yes", "y"):
        print("🚫 To'lov bekor qilindi.")
        # Chekni cancel qilamiz
        call_api("receipts.cancel", {"id": receipt_id}, use_key=True)
        print("   Chek bekor qilindi.")
        return

    # --- STEP 5: To'lash ---
    print("\n─────────────────────────────────────────────")
    print("💸 STEP 5: To'lov amalga oshirilmoqda...")
    result = call_api("receipts.pay", {
        "id": receipt_id,
        "token": token
    }, use_key=True)

    if not result:
        print("❌ To'lov muvaffaqiyatsiz!")
        return

    state = result["receipt"]["state"]
    STATE_NAMES = {0: "yaratildi", 1: "jarayonda", 2: "yaroqsiz", 4: "✅ TO'LANDI", 5: "qaytarish navbatda", 6: "bekor qilindi"}

    print(f"\n{'='*55}")
    if state == 4:
        print(f"  ✅ TO'LOV MUVAFFAQIYATLI!")
        print(f"  💰 Summa:      {amount_uzs} so'm")
        print(f"  🧾 Receipt ID: {receipt_id}")
        print(f"  📊 Holat:      {state} — {STATE_NAMES.get(state, '?')}")
    else:
        print(f"  ⚠️  To'lov holati: {state} — {STATE_NAMES.get(state, '?')}")
    print("=" * 55)

    # --- Chek tekshirish ---
    print("\n🔍 To'lov tekshirilmoqda (receipts.check)...")
    result = call_api("receipts.check", {"id": receipt_id}, use_key=True)
    if result:
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()