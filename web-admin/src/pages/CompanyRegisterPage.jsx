import { useState } from 'react';
import { Form, Input, Button, Card, Typography, message, Space, Divider, Result } from 'antd';
import {
  BankOutlined,
  MailOutlined,
  PhoneOutlined,
  EnvironmentOutlined,
  UserOutlined,
  LockOutlined,
} from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';

const { Title, Text, Paragraph } = Typography;

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://walktogether-api.onrender.com/api/v1';

export default function CompanyRegisterPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [companyName, setCompanyName] = useState('');

  const onFinish = async (values) => {
    setLoading(true);
    try {
      await axios.post(`${API_BASE_URL}/auth/register-company`, values);
      setCompanyName(values.companyName);
      setSuccess(true);
      message.success('Đăng ký công ty thành công!');
    } catch (err) {
      const msg =
        err.response?.data?.message ||
        err.response?.data?.error?.details?.[0]?.message ||
        'Đăng ký thất bại. Vui lòng thử lại.';
      message.error(msg);
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 50%, #a5d6a7 100%)',
          padding: 24,
        }}
      >
        <Card
          style={{
            maxWidth: 520,
            width: '100%',
            borderRadius: 16,
            boxShadow: '0 8px 32px rgba(0, 0, 0, 0.08)',
          }}
          styles={{ body: { padding: '40px 32px' } }}
        >
          <Result
            status="success"
            title="Đăng ký thành công!"
            subTitle={
              <>
                <Paragraph>
                  Công ty <strong>{companyName}</strong> đã được gửi yêu cầu đăng ký.
                </Paragraph>
                <Paragraph>
                  Quản trị viên hệ thống sẽ xem xét và phê duyệt trong thời gian sớm nhất.
                  Bạn sẽ nhận được thông báo qua email khi công ty được duyệt.
                </Paragraph>
                <Paragraph type="secondary" style={{ fontSize: 13 }}>
                  Sau khi được duyệt, mã công ty sẽ được tạo để nhân viên có thể đăng ký trên ứng dụng.
                </Paragraph>
              </>
            }
            extra={[
              <Button
                key="login"
                type="primary"
                size="large"
                onClick={() => navigate('/login')}
                style={{ borderRadius: 8, fontWeight: 600 }}
              >
                Đến trang đăng nhập
              </Button>,
            ]}
          />
        </Card>
      </div>
    );
  }

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 50%, #a5d6a7 100%)',
        padding: 24,
      }}
    >
      <Card
        style={{
          maxWidth: 560,
          width: '100%',
          borderRadius: 16,
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.08)',
        }}
        styles={{ body: { padding: '40px 32px' } }}
      >
        <Space direction="vertical" size={4} style={{ width: '100%', textAlign: 'center', marginBottom: 24 }}>
          <div
            style={{
              width: 64,
              height: 64,
              borderRadius: 16,
              background: '#44C548',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 12px',
            }}
          >
            <span style={{ fontSize: 28, color: '#fff' }}>🏢</span>
          </div>
          <Title level={3} style={{ margin: 0 }}>Đăng ký doanh nghiệp</Title>
          <Text type="secondary">Tạo tài khoản công ty trên WalkTogether</Text>
        </Space>

        <Form
          name="company-register"
          onFinish={onFinish}
          layout="vertical"
          size="large"
          autoComplete="off"
          requiredMark={false}
        >
          {/* Company Info Section */}
          <Divider orientation="left" orientationMargin={0} style={{ fontSize: 14, fontWeight: 600, color: '#44C548' }}>
            <BankOutlined /> Thông tin công ty
          </Divider>

          <Form.Item
            name="companyName"
            label="Tên công ty"
            rules={[
              { required: true, message: 'Vui lòng nhập tên công ty' },
              { min: 2, message: 'Tên công ty tối thiểu 2 ký tự' },
            ]}
          >
            <Input
              prefix={<BankOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="VD: Công ty ABC"
            />
          </Form.Item>

          <Form.Item
            name="email"
            label="Email công ty"
            rules={[
              { required: true, message: 'Vui lòng nhập email công ty' },
              { type: 'email', message: 'Email không hợp lệ' },
            ]}
          >
            <Input
              prefix={<MailOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="contact@company.com"
            />
          </Form.Item>

          <Form.Item name="phone" label="Số điện thoại công ty">
            <Input
              prefix={<PhoneOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="0901234567 (không bắt buộc)"
            />
          </Form.Item>

          <Form.Item name="address" label="Địa chỉ">
            <Input
              prefix={<EnvironmentOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="Địa chỉ công ty (không bắt buộc)"
            />
          </Form.Item>

          <Form.Item name="description" label="Mô tả">
            <Input.TextArea
              placeholder="Giới thiệu ngắn về công ty (không bắt buộc)"
              rows={3}
              maxLength={500}
              showCount
            />
          </Form.Item>

          {/* Admin Account Section */}
          <Divider orientation="left" orientationMargin={0} style={{ fontSize: 14, fontWeight: 600, color: '#44C548' }}>
            <UserOutlined /> Tài khoản quản trị viên
          </Divider>

          <Paragraph type="secondary" style={{ fontSize: 13, marginBottom: 16 }}>
            Đây là tài khoản quản trị công ty. Sau khi được duyệt, bạn sẽ dùng tài khoản này để quản lý nhân viên.
          </Paragraph>

          <Form.Item
            name="adminFullName"
            label="Họ và tên quản trị viên"
            rules={[
              { required: true, message: 'Vui lòng nhập họ tên' },
              { min: 2, message: 'Tối thiểu 2 ký tự' },
            ]}
          >
            <Input
              prefix={<UserOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="Nguyễn Văn A"
            />
          </Form.Item>

          <Form.Item
            name="adminEmail"
            label="Email quản trị viên"
            rules={[
              { required: true, message: 'Vui lòng nhập email' },
              { type: 'email', message: 'Email không hợp lệ' },
            ]}
          >
            <Input
              prefix={<MailOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="admin@company.com"
            />
          </Form.Item>

          <Form.Item
            name="adminPassword"
            label="Mật khẩu"
            rules={[
              { required: true, message: 'Vui lòng nhập mật khẩu' },
              { min: 6, message: 'Mật khẩu tối thiểu 6 ký tự' },
            ]}
          >
            <Input.Password
              prefix={<LockOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="Ít nhất 6 ký tự"
            />
          </Form.Item>

          <Form.Item
            name="confirmPassword"
            label="Xác nhận mật khẩu"
            dependencies={['adminPassword']}
            rules={[
              { required: true, message: 'Vui lòng xác nhận mật khẩu' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('adminPassword') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('Mật khẩu không khớp'));
                },
              }),
            ]}
          >
            <Input.Password
              prefix={<LockOutlined style={{ color: '#bfbfbf' }} />}
              placeholder="Nhập lại mật khẩu"
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 16, marginTop: 8 }}>
            <Button
              type="primary"
              htmlType="submit"
              block
              loading={loading}
              style={{ height: 48, borderRadius: 8, fontWeight: 600, fontSize: 16 }}
            >
              🚀 Đăng ký công ty
            </Button>
          </Form.Item>
        </Form>

        <div style={{ textAlign: 'center' }}>
          <Text type="secondary" style={{ fontSize: 13 }}>
            Đã có tài khoản?{' '}
            <a
              onClick={() => navigate('/login')}
              style={{ color: '#44C548', fontWeight: 600, cursor: 'pointer' }}
            >
              Đăng nhập
            </a>
          </Text>
        </div>
      </Card>
    </div>
  );
}
