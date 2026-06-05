import { useState, useEffect } from 'react';
import {
  Card, Typography, Descriptions, Tag, Button, Space, Avatar, Spin,
  Select, Modal, Badge, Divider, message, Tooltip,
} from 'antd';
import {
  ArrowLeftOutlined, UserOutlined, CrownOutlined,
  CheckCircleOutlined, StopOutlined, ExclamationCircleOutlined,
  MailOutlined, PhoneOutlined, CalendarOutlined, TeamOutlined,
} from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import axiosClient from '../api/axiosClient';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

const ROLE_COLORS = {
  company_admin: 'blue',
  member: 'default',
  super_admin: 'gold',
};

const ROLE_LABELS = {
  company_admin: 'Admin công ty',
  member: 'Thành viên',
  super_admin: 'Super Admin',
};

export default function UserDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [roleLoading, setRoleLoading] = useState(false);
  const [toggleLoading, setToggleLoading] = useState(false);

  const fetchUser = async () => {
    setLoading(true);
    try {
      const res = await axiosClient.get(`/admin/users/${id}`);
      setUser(res.data);
    } catch {
      message.error('Không thể tải thông tin người dùng');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUser();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleRoleChange = (newRole) => {
    const isPromotion = newRole === 'company_admin';

    Modal.confirm({
      title: isPromotion
        ? '⚠️ Thăng cấp lên Admin công ty?'
        : '⚠️ Hạ cấp xuống Thành viên?',
      icon: <ExclamationCircleOutlined />,
      content: isPromotion
        ? (
          <div>
            <p>Người dùng sẽ có quyền:</p>
            <ul style={{ margin: '8px 0', paddingLeft: 20 }}>
              <li>Quản lý Group (tạo, xóa, quản lý members)</li>
              <li>Quản lý Contest</li>
              <li>Ghim bài viết</li>
              <li>Bài đăng sẽ được gắn nhãn "Official"</li>
            </ul>
            {user?.companyId && (
              <p style={{ color: '#faad14', fontWeight: 500 }}>
                ⚠ Nếu công ty đã có admin khác, admin cũ sẽ bị hạ xuống Thành viên.
              </p>
            )}
          </div>
        )
        : (
          <div>
            <p>Người dùng sẽ <strong>mất</strong> các quyền:</p>
            <ul style={{ margin: '8px 0', paddingLeft: 20 }}>
              <li>Quản lý Group, Contest</li>
              <li>Ghim bài viết</li>
              <li>Nhãn "Official" trên bài đăng</li>
            </ul>
          </div>
        ),
      okText: 'Xác nhận',
      cancelText: 'Hủy',
      okButtonProps: { danger: !isPromotion },
      onOk: async () => {
        setRoleLoading(true);
        try {
          const res = await axiosClient.put(`/admin/users/${id}/role`, { role: newRole });
          setUser(res.data);
          message.success(res.message);
        } catch (err) {
          message.error(err.message);
        } finally {
          setRoleLoading(false);
        }
      },
    });
  };

  const handleToggleActive = () => {
    const isDeactivating = user.isActive;
    Modal.confirm({
      title: isDeactivating ? 'Vô hiệu hóa tài khoản?' : 'Kích hoạt lại tài khoản?',
      icon: <ExclamationCircleOutlined />,
      content: isDeactivating
        ? 'Người dùng sẽ không thể đăng nhập và sử dụng ứng dụng.'
        : 'Người dùng sẽ có thể đăng nhập và sử dụng ứng dụng trở lại.',
      okText: isDeactivating ? 'Vô hiệu hóa' : 'Kích hoạt',
      cancelText: 'Hủy',
      okButtonProps: { danger: isDeactivating },
      onOk: async () => {
        setToggleLoading(true);
        try {
          const res = await axiosClient.put(`/admin/users/${id}/toggle-active`);
          setUser(res.data);
          message.success(res.message);
        } catch (err) {
          message.error(err.message);
        } finally {
          setToggleLoading(false);
        }
      },
    });
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 100 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!user) {
    return <div style={{ padding: 24 }}>Không tìm thấy người dùng.</div>;
  }

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
        <Space>
          <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/users')}>
            Quay lại
          </Button>
          <Title level={4} style={{ margin: 0 }}>Chi tiết người dùng</Title>
        </Space>
      </div>

      {/* User Info Card */}
      <Card style={{ borderRadius: 12, marginBottom: 24 }}>
        <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
          {/* Avatar + Name */}
          <div style={{ textAlign: 'center', minWidth: 120 }}>
            <Avatar
              size={80}
              src={user.avatar}
              icon={!user.avatar && <UserOutlined />}
              style={{
                background: user.role === 'company_admin' ? '#1890ff' : '#44C548',
                boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
              }}
            />
            <div style={{ marginTop: 12 }}>
              <Tag
                icon={user.role === 'company_admin' ? <CrownOutlined /> : null}
                color={ROLE_COLORS[user.role]}
                style={{ fontSize: 13, padding: '2px 10px' }}
              >
                {ROLE_LABELS[user.role]}
              </Tag>
            </div>
            <div style={{ marginTop: 8 }}>
              <Badge
                status={user.isActive ? 'success' : 'error'}
                text={
                  <Text style={{ fontSize: 12 }}>
                    {user.isActive ? 'Đang hoạt động' : 'Đã vô hiệu hóa'}
                  </Text>
                }
              />
            </div>
          </div>

          {/* Details */}
          <div style={{ flex: 1 }}>
            <Title level={4} style={{ marginTop: 0, marginBottom: 16 }}>{user.fullName}</Title>
            <Descriptions column={{ xs: 1, sm: 2 }} size="small">
              {user.email && (
                <Descriptions.Item label={<><MailOutlined /> Email</>}>
                  {user.email}
                </Descriptions.Item>
              )}
              {user.phone && (
                <Descriptions.Item label={<><PhoneOutlined /> SĐT</>}>
                  {user.phone}
                </Descriptions.Item>
              )}
              <Descriptions.Item label={<><CalendarOutlined /> Ngày đăng ký</>}>
                {dayjs(user.createdAt).format('DD/MM/YYYY HH:mm')}
              </Descriptions.Item>
              {user.lastOnline && (
                <Descriptions.Item label="Lần cuối online">
                  {dayjs(user.lastOnline).format('DD/MM/YYYY HH:mm')}
                </Descriptions.Item>
              )}
              {user.companyId && (
                <Descriptions.Item label={<><TeamOutlined /> Công ty</>}>
                  <Space>
                    <Button
                      type="link"
                      size="small"
                      style={{ padding: 0 }}
                      onClick={() => navigate(`/companies/${user.companyId._id || user.companyId}`)}
                    >
                      {user.companyId.name || user.companyId}
                    </Button>
                    {user.companyId.code && (
                      <Tag color="blue">{user.companyId.code}</Tag>
                    )}
                  </Space>
                </Descriptions.Item>
              )}
              {user.companyCode && (
                <Descriptions.Item label="Mã công ty đăng ký">
                  <Tag color="geekblue">{user.companyCode}</Tag>
                </Descriptions.Item>
              )}
            </Descriptions>
          </div>
        </div>
      </Card>

      {/* Actions Card */}
      <Card
        title="Quản lý tài khoản"
        style={{ borderRadius: 12 }}
        styles={{ header: { borderBottom: '1px solid #f0f0f0' } }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          {/* Role Change */}
          <div>
            <Text strong style={{ display: 'block', marginBottom: 8 }}>
              Đổi vai trò (Role)
            </Text>
            <Space>
              <Select
                value={user.role}
                onChange={handleRoleChange}
                loading={roleLoading}
                style={{ width: 200 }}
                options={[
                  { value: 'company_admin', label: '👑 Admin công ty' },
                  { value: 'member', label: '👤 Thành viên' },
                ]}
              />
              <Tooltip title="Thay đổi role sẽ ảnh hưởng đến quyền quản lý Group, Contest và bài đăng Official">
                <ExclamationCircleOutlined style={{ color: '#faad14', fontSize: 16 }} />
              </Tooltip>
            </Space>
            <div style={{ marginTop: 8 }}>
              <Text type="secondary" style={{ fontSize: 12 }}>
                {user.role === 'company_admin'
                  ? 'Có quyền quản lý Group, Contest, ghim bài viết, bài đăng gắn nhãn Official.'
                  : 'Chỉ có quyền tham gia group, tham gia contest, đăng bài.'
                }
              </Text>
            </div>
          </div>

          <Divider style={{ margin: 0 }} />

          {/* Toggle Active */}
          <div>
            <Text strong style={{ display: 'block', marginBottom: 8 }}>
              Trạng thái tài khoản
            </Text>
            <Space>
              <Button
                type={user.isActive ? 'default' : 'primary'}
                danger={user.isActive}
                icon={user.isActive ? <StopOutlined /> : <CheckCircleOutlined />}
                onClick={handleToggleActive}
                loading={toggleLoading}
              >
                {user.isActive ? 'Vô hiệu hóa tài khoản' : 'Kích hoạt tài khoản'}
              </Button>
            </Space>
            <div style={{ marginTop: 8 }}>
              <Text type="secondary" style={{ fontSize: 12 }}>
                {user.isActive
                  ? 'Tài khoản đang hoạt động bình thường. Vô hiệu hóa sẽ ngăn người dùng đăng nhập.'
                  : 'Tài khoản đã bị vô hiệu hóa. Kích hoạt để cho phép đăng nhập trở lại.'
                }
              </Text>
            </div>
          </div>
        </div>
      </Card>
    </div>
  );
}
