import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Card,
  Descriptions,
  Tag,
  Button,
  Space,
  Spin,
  Typography,
  Modal,
  message,
  Divider,
  Result,
} from 'antd';
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  StopOutlined,
  UndoOutlined,
  ArrowLeftOutlined,
  CopyOutlined,
} from '@ant-design/icons';
import axiosClient from '../api/axiosClient';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

const STATUS_COLORS = {
  pending: 'gold',
  approved: 'green',
  rejected: 'red',
  suspended: 'default',
};

const STATUS_LABELS = {
  pending: 'Chờ duyệt',
  approved: 'Đã duyệt',
  rejected: 'Từ chối',
  suspended: 'Tạm ngưng',
};

export default function CompanyDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [company, setCompany] = useState(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchCompany = async () => {
    setLoading(true);
    try {
      const res = await axiosClient.get(`/admin/companies/${id}`);
      setCompany(res.data);
    } catch {
      // handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCompany();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleAction = (action, title, description) => {
    Modal.confirm({
      title,
      content: description,
      okText: 'Xác nhận',
      cancelText: 'Hủy',
      okButtonProps: { danger: action === 'reject' || action === 'suspend' },
      onOk: async () => {
        setActionLoading(true);
        try {
          const res = await axiosClient.put(`/admin/companies/${id}/${action}`);
          setCompany({ ...company, ...res.data });
          message.success(res.message || 'Thao tác thành công');
          // Refetch to get fresh data
          fetchCompany();
        } catch (err) {
          message.error(err.message || 'Thao tác thất bại');
        } finally {
          setActionLoading(false);
        }
      },
    });
  };

  const copyCode = () => {
    if (company?.code) {
      navigator.clipboard.writeText(company.code);
      message.success('Đã sao chép mã công ty');
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 100 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!company) {
    return (
      <Result
        status="404"
        title="Không tìm thấy"
        subTitle="Công ty không tồn tại hoặc đã bị xóa"
        extra={
          <Button type="primary" onClick={() => navigate('/companies')}>
            Quay lại danh sách
          </Button>
        }
      />
    );
  }

  const renderActions = () => {
    switch (company.status) {
      case 'pending':
        return (
          <Space>
            <Button
              type="primary"
              icon={<CheckCircleOutlined />}
              loading={actionLoading}
              onClick={() =>
                handleAction(
                  'approve',
                  'Phê duyệt công ty?',
                  `Bạn có chắc muốn phê duyệt "${company.name}"? Công ty sẽ được cấp mã truy cập.`
                )
              }
            >
              Phê duyệt
            </Button>
            <Button
              danger
              icon={<CloseCircleOutlined />}
              loading={actionLoading}
              onClick={() =>
                handleAction(
                  'reject',
                  'Từ chối công ty?',
                  `Bạn có chắc muốn từ chối "${company.name}"?`
                )
              }
            >
              Từ chối
            </Button>
          </Space>
        );
      case 'approved':
        return (
          <Button
            danger
            icon={<StopOutlined />}
            loading={actionLoading}
            onClick={() =>
              handleAction(
                'suspend',
                'Tạm ngưng công ty?',
                `Bạn có chắc muốn tạm ngưng "${company.name}"? Nhân viên sẽ không thể sử dụng ứng dụng.`
              )
            }
          >
            Tạm ngưng
          </Button>
        );
      case 'suspended':
        return (
          <Button
            type="primary"
            icon={<UndoOutlined />}
            loading={actionLoading}
            onClick={() =>
              handleAction(
                'reactivate',
                'Khôi phục công ty?',
                `Bạn có chắc muốn khôi phục "${company.name}"? Công ty sẽ hoạt động trở lại.`
              )
            }
          >
            Khôi phục
          </Button>
        );
      default:
        return null;
    }
  };

  return (
    <div>
      {/* Header */}
      <div
        style={{
          marginBottom: 24,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 12,
        }}
      >
        <Space>
          <Button
            type="text"
            icon={<ArrowLeftOutlined />}
            onClick={() => navigate('/companies')}
          >
            Quay lại
          </Button>
          <Title level={4} style={{ margin: 0 }}>
            {company.name}
          </Title>
          <Tag color={STATUS_COLORS[company.status]}>
            {STATUS_LABELS[company.status]}
          </Tag>
        </Space>
        {renderActions()}
      </div>

      {/* Company Info */}
      <Card title="Thông tin công ty" style={{ borderRadius: 12, marginBottom: 16 }}>
        <Descriptions column={{ xs: 1, sm: 2 }} labelStyle={{ fontWeight: 500 }}>
          <Descriptions.Item label="Tên công ty">{company.name}</Descriptions.Item>
          <Descriptions.Item label="Email">{company.email}</Descriptions.Item>
          <Descriptions.Item label="Số điện thoại">{company.phone || '—'}</Descriptions.Item>
          <Descriptions.Item label="Trạng thái">
            <Tag color={STATUS_COLORS[company.status]}>{STATUS_LABELS[company.status]}</Tag>
          </Descriptions.Item>
          {company.code && (
            <Descriptions.Item label="Mã công ty">
              <Space>
                <Tag color="blue" style={{ fontSize: 16, padding: '4px 12px', fontWeight: 700 }}>
                  {company.code}
                </Tag>
                <Button
                  size="small"
                  type="text"
                  icon={<CopyOutlined />}
                  onClick={copyCode}
                />
              </Space>
            </Descriptions.Item>
          )}
          <Descriptions.Item label="Số thành viên">
            <Text strong>{company.memberCount || company.totalMembers || 0}</Text>
          </Descriptions.Item>
          <Descriptions.Item label="Địa chỉ" span={2}>{company.address || '—'}</Descriptions.Item>
          <Descriptions.Item label="Mô tả" span={2}>{company.description || '—'}</Descriptions.Item>
          <Descriptions.Item label="Ngày đăng ký">
            {dayjs(company.createdAt).format('DD/MM/YYYY HH:mm')}
          </Descriptions.Item>
          <Descriptions.Item label="Cập nhật lần cuối">
            {dayjs(company.updatedAt).format('DD/MM/YYYY HH:mm')}
          </Descriptions.Item>
        </Descriptions>
      </Card>

      {/* Admin Info */}
      {company.adminId && (
        <Card title="Thông tin quản trị viên" style={{ borderRadius: 12 }}>
          <Descriptions column={{ xs: 1, sm: 2 }} labelStyle={{ fontWeight: 500 }}>
            <Descriptions.Item label="Họ tên">{company.adminId.fullName}</Descriptions.Item>
            <Descriptions.Item label="Email">{company.adminId.email}</Descriptions.Item>
            <Descriptions.Item label="Số điện thoại">{company.adminId.phone || '—'}</Descriptions.Item>
          </Descriptions>
        </Card>
      )}
    </div>
  );
}
