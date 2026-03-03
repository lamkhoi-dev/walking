import { useEffect, useState } from 'react';
import { Row, Col, Card, Statistic, Typography, Spin, Button, Space } from 'antd';
import {
  TeamOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  StopOutlined,
  UserOutlined,
} from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import axiosClient from '../api/axiosClient';

const { Title } = Typography;

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const res = await axiosClient.get('/admin/stats');
        setStats(res.data);
      } catch {
        // Error handled by interceptor
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 100 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!stats) {
    return <div style={{ padding: 24 }}>Không thể tải dữ liệu thống kê.</div>;
  }

  const companyCards = [
    {
      title: 'Tổng công ty',
      value: stats.companies.total,
      icon: <TeamOutlined />,
      color: '#1890ff',
    },
    {
      title: 'Chờ duyệt',
      value: stats.companies.pending,
      icon: <ClockCircleOutlined />,
      color: '#faad14',
      highlight: stats.companies.pending > 0,
    },
    {
      title: 'Đã duyệt',
      value: stats.companies.approved,
      icon: <CheckCircleOutlined />,
      color: '#44C548',
    },
    {
      title: 'Bị từ chối',
      value: stats.companies.rejected,
      icon: <CloseCircleOutlined />,
      color: '#ff4d4f',
    },
    {
      title: 'Tạm ngưng',
      value: stats.companies.suspended,
      icon: <StopOutlined />,
      color: '#8c8c8c',
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Title level={4} style={{ margin: 0 }}>Tổng quan</Title>
      </div>

      {/* Company Stats */}
      <Row gutter={[16, 16]}>
        {companyCards.map((card) => (
          <Col xs={24} sm={12} lg={8} xl={4} key={card.title} style={{ minWidth: 180 }}>
            <Card
              hoverable
              style={{
                borderRadius: 12,
                border: card.highlight ? '2px solid #faad14' : '1px solid #f0f0f0',
                background: card.highlight ? '#fffbe6' : '#fff',
              }}
              bodyStyle={{ padding: '20px 16px' }}
            >
              <Statistic
                title={
                  <span style={{ fontSize: 13, color: '#8c8c8c' }}>{card.title}</span>
                }
                value={card.value}
                prefix={
                  <span style={{ color: card.color, fontSize: 20, marginRight: 4 }}>
                    {card.icon}
                  </span>
                }
                valueStyle={{ color: card.color, fontSize: 28, fontWeight: 700 }}
              />
            </Card>
          </Col>
        ))}
      </Row>

      {/* Users Stats */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} sm={12} lg={8}>
          <Card style={{ borderRadius: 12 }} bodyStyle={{ padding: '20px 16px' }}>
            <Statistic
              title={<span style={{ fontSize: 13, color: '#8c8c8c' }}>Tổng người dùng</span>}
              value={stats.users.total}
              prefix={<UserOutlined style={{ color: '#722ed1', fontSize: 20, marginRight: 4 }} />}
              valueStyle={{ color: '#722ed1', fontSize: 28, fontWeight: 700 }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={8}>
          <Card style={{ borderRadius: 12 }} bodyStyle={{ padding: '20px 16px' }}>
            <Statistic
              title={<span style={{ fontSize: 13, color: '#8c8c8c' }}>Đang hoạt động</span>}
              value={stats.users.active}
              prefix={<CheckCircleOutlined style={{ color: '#44C548', fontSize: 20, marginRight: 4 }} />}
              valueStyle={{ color: '#44C548', fontSize: 28, fontWeight: 700 }}
            />
          </Card>
        </Col>
      </Row>

      {/* Quick actions */}
      {stats.companies.pending > 0 && (
        <Card style={{ marginTop: 24, borderRadius: 12, background: '#fffbe6', borderColor: '#faad14' }}>
          <Space>
            <ClockCircleOutlined style={{ color: '#faad14', fontSize: 20 }} />
            <span style={{ fontWeight: 500 }}>
              Có <strong>{stats.companies.pending}</strong> công ty đang chờ duyệt
            </span>
            <Button
              type="primary"
              size="small"
              onClick={() => navigate('/companies?status=pending')}
            >
              Xem ngay
            </Button>
          </Space>
        </Card>
      )}
    </div>
  );
}
