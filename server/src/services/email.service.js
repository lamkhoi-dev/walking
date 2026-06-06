const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

class EmailService {
  constructor() {
    this.transporter = null;
    this._init();
  }

  _init() {
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      logger.warn('Email service not configured (EMAIL_USER/EMAIL_PASS missing) — OTPs will be logged to console only');
      return;
    }
    this.transporter = nodemailer.createTransport({
      host: process.env.EMAIL_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.EMAIL_PORT, 10) || 587,
      secure: process.env.EMAIL_PORT === '465',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });
  }

  async sendPasswordResetOtp(toEmail, otp, fullName) {
    if (!this.transporter) {
      logger.info(`[DEV] Password reset OTP for ${toEmail}: ${otp}`);
      return;
    }

    const html = `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background:#f5f5f5; margin:0; padding:24px;">
  <div style="max-width:480px; margin:0 auto; background:#ffffff; border-radius:16px; overflow:hidden; box-shadow:0 4px 20px rgba(0,0,0,0.08);">
    <div style="background:linear-gradient(135deg,#6C63FF,#4CAF50); padding:32px 24px; text-align:center;">
      <h1 style="color:#fff; margin:0; font-size:24px; font-weight:800;">🏃 Runly</h1>
      <p style="color:rgba(255,255,255,0.85); margin:8px 0 0; font-size:14px;">Đặt lại mật khẩu</p>
    </div>
    <div style="padding:32px 24px;">
      <p style="color:#333; font-size:16px; margin:0 0 8px;">Xin chào <strong>${fullName}</strong>,</p>
      <p style="color:#666; font-size:14px; line-height:1.6; margin:0 0 24px;">
        Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Nhập mã OTP dưới đây vào ứng dụng:
      </p>
      <div style="background:#f0f0ff; border:2px dashed #6C63FF; border-radius:12px; padding:24px; text-align:center; margin:0 0 24px;">
        <div style="font-size:42px; font-weight:900; letter-spacing:10px; color:#6C63FF;">${otp}</div>
        <p style="color:#888; font-size:12px; margin:8px 0 0;">Mã có hiệu lực trong <strong>10 phút</strong></p>
      </div>
      <p style="color:#999; font-size:12px; line-height:1.6; margin:0; border-top:1px solid #f0f0f0; padding-top:16px;">
        Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này. Tài khoản của bạn vẫn an toàn.
      </p>
    </div>
  </div>
</body>
</html>`;

    await this.transporter.sendMail({
      from: `"Runly App" <${process.env.EMAIL_USER}>`,
      to: toEmail,
      subject: `${otp} là mã đặt lại mật khẩu Runly của bạn`,
      html,
    });

    logger.info(`Password reset OTP sent to: ${toEmail}`);
  }
}

module.exports = new EmailService();
