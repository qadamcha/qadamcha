# 💳 To'lov Tizimlari Konfiguratsiya

> **Test rejim** — Haqiqiy API keylar keyinchalik qo'shiladi

---

## 🔐 Credentials (Test Mode)

```env
# .env fayliga qo'shing

# ========== PAYME ==========
PAYME_MERCHANT_ID=test_merchant_id
PAYME_SECRET_KEY=test_secret_key
PAYME_TEST_MODE=true
PAYME_CHECKOUT_URL=https://checkout.paycom.uz

# ========== CLICK ==========
CLICK_MERCHANT_ID=test_merchant_id
CLICK_SERVICE_ID=test_service_id
CLICK_SECRET_KEY=test_secret_key
CLICK_TEST_MODE=true

# ========== UZUM BANK ==========
UZUM_MERCHANT_ID=test_merchant_id
UZUM_SECRET_KEY=test_secret_key
UZUM_TEST_MODE=true
```

---

## 💰 Obuna Tariflari

| Tarif | Narx (so'm) | Muddat | Chegirma |
|-------|-------------|--------|----------|
| **Oylik** | 29,900 | 30 kun | - |
| **Yillik** | 214,900 | 365 kun | 40% |
| **Umrbod** | 499,900 | Cheksiz | - |

---

## 🔄 To'lov Flow

```
┌────────────────────────────────────────────────────────────┐
│                    TO'LOV FLOW                             │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  1. TARIF TANLASH                                          │
│     ┌──────────┐    ┌──────────┐                          │
│     │  Oylik/  │───▶│  Server  │                          │
│     │  Yillik  │    │  order   │                          │
│     └──────────┘    └──────────┘                          │
│                                                            │
│  2. TO'LOV TIZIMI                                          │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │  Payme/  │───▶│ Checkout │───▶│  To'lov  │          │
│     │  Click   │    │   URL    │    │  sahifa  │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
│  3. CALLBACK                                               │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │ Payment  │───▶│ Webhook  │───▶│  Obuna   │          │
│     │  Server  │    │ /callback│    │ activate │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 🔧 Node.js Service (Skeleton)

```javascript
// src/services/payment.service.js

class PaymentService {
  constructor() {
    this.testMode = process.env.PAYME_TEST_MODE === 'true';
  }

  // Order yaratish
  async createOrder(userId, plan) {
    const prices = {
      monthly: 29900,
      yearly: 214900,
      lifetime: 499900
    };

    const order = {
      id: this.generateOrderId(),
      userId,
      plan,
      amount: prices[plan],
      status: 'pending',
      createdAt: new Date()
    };

    // DB ga saqlash
    // await Order.create(order);

    return order;
  }

  // Payme checkout URL
  generatePaymeUrl(orderId, amount) {
    if (this.testMode) {
      return `https://test.paycom.uz/checkout/${orderId}`;
    }
    
    const merchantId = process.env.PAYME_MERCHANT_ID;
    const params = Buffer.from(
      `m=${merchantId};ac.order_id=${orderId};a=${amount * 100}`
    ).toString('base64');
    
    return `https://checkout.paycom.uz/${params}`;
  }

  // Click checkout URL
  generateClickUrl(orderId, amount) {
    const merchantId = process.env.CLICK_MERCHANT_ID;
    const serviceId = process.env.CLICK_SERVICE_ID;
    
    return `https://my.click.uz/services/pay?` +
      `service_id=${serviceId}&` +
      `merchant_id=${merchantId}&` +
      `amount=${amount}&` +
      `transaction_param=${orderId}`;
  }

  // Obunani faollashtirish
  async activateSubscription(userId, plan, transactionId) {
    const durations = {
      monthly: 30,
      yearly: 365,
      lifetime: 36500 // 100 yil
    };

    const subscription = {
      userId,
      plan,
      status: 'active',
      transactionId,
      startDate: new Date(),
      endDate: this.addDays(new Date(), durations[plan])
    };

    // await Subscription.create(subscription);
    return subscription;
  }

  generateOrderId() {
    return 'ORD-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
  }

  addDays(date, days) {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
  }
}

module.exports = new PaymentService();
```

---

## 📡 Webhook Endpoints

```javascript
// Payme callback
POST /api/v1/payment/payme/callback
{
  "method": "CheckPerformTransaction",
  "params": { "account": { "order_id": "123" }, "amount": 2990000 }
}

// Click callback  
POST /api/v1/payment/click/prepare
POST /api/v1/payment/click/complete

// Uzum callback
POST /api/v1/payment/uzum/callback
```

---

## 🧪 Test Kartalar

### Payme Test

```
Karta: 8600 0000 0000 0000
Muddat: Ixtiyoriy (kelajakdagi)
CVV: Ixtiyoriy 3 raqam
SMS: 666666
```

### Click Test

```
Test rejimda to'lov sahifasida "Test Payment" tugmasi bo'ladi
```

---

## ✅ Status

- [x] To'lov flow loyihalashtirildi
- [x] Tariflar belgilandi
- [x] Test mode skeleton tayyor
- [ ] Payme real API (keyinchalik)
- [ ] Click real API (keyinchalik)
- [ ] Uzum real API (keyinchalik)

---

> 📅 **Yaratilgan:** 2026-02-09
> 📝 **Note:** Real API keylar production da qo'shiladi
