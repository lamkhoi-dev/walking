const Brevo = require('@getbrevo/brevo');
const logger = require('../utils/logger');

class EmailService {
  constructor() {
    this.client = null;
    this._init();
  }

  _init() {
    if (!process.env.BREVO_API_KEY) {
      logger.warn('Email service not configured (BREVO_API_KEY missing) — OTPs will be logged to console only');
      return;
    }
    const defaultClient = Brevo.ApiClient.instance;
    defaultClient.authentications['api-key'].apiKey = process.env.BREVO_API_KEY;
    this.client = new Brevo.TransactionalEmailsApi();
  }

  async sendPasswordResetOtp(toEmail, otp, fullName) {
    if (!this.client) {
      logger.info(`[DEV] Password reset OTP for ${toEmail}: ${otp}`);
      return;
    }

    const html = `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family:Arial,sans-serif;background:#f4f4f4;margin:0;padding:32px 16px;">
  <div style="max-width:440px;margin:0 auto;background:#fff;border-radius:12px;padding:36px 32px;">

    <h2 style="margin:0 0 4px;font-size:22px;color:#111;">Runly</h2>
    <p style="margin:0 0 28px;font-size:13px;color:#888;">Ứng dụng đếm bước chân</p>

    <p style="margin:0 0 6px;font-size:15px;color:#333;">Xin chào <strong>${fullName}</strong>,</p>
    <p style="margin:0 0 24px;font-size:14px;color:#555;line-height:1.6;">
      Chúng tôi nhận được yêu cầu đặt lại mật khẩu của bạn. Mã xác nhận của bạn là:
    </p>

    <div style="background:#f7f7ff;border-radius:8px;padding:20px;text-align:center;margin:0 0 24px;">
      <span style="font-size:36px;font-weight:700;letter-spacing:8px;color:#5C6BC0;">${otp}</span>
      <p style="margin:10px 0 0;font-size:12px;color:#999;">Mã có hiệu lực trong <strong>10 phút</strong></p>
    </div>

    <p style="margin:0;font-size:12px;color:#aaa;border-top:1px solid #eee;padding-top:20px;line-height:1.6;">
      Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email. Tài khoản của bạn vẫn an toàn.
    </p>
  </div>
</body>
</html>`;

    const sendSmtpEmail = new Brevo.SendSmtpEmail();
    sendSmtpEmail.sender = { name: 'Runly App', email: 'walkingapp51@gmail.com' };
    sendSmtpEmail.to = [{ email: toEmail }];
    sendSmtpEmail.subject = `${otp} là mã đặt lại mật khẩu Runly của bạn`;
    sendSmtpEmail.htmlContent = html;

    await this.client.sendTransacEmail(sendSmtpEmail);
    logger.info(`Password reset OTP sent to: ${toEmail}`);
  }
}

module.exports = new EmailService();
