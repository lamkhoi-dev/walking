import { useState, useEffect } from 'react';
import { Table, Card, Tag, Input, Select, Space, Typography, Button, Avatar, Badge } from 'antd';
import { SearchOutlined, EyeOutlined, UserOutlined, CrownOutlined } from '@ant-design/icons';
import { useNavigate, useSearchParams } from 'react-router-dom';
import axiosClient from '../api/axiosClient';
import dayjs from 'dayjs';

const { Title } = Typography;

const ROLE_OPTIONS = [
  { value: '', label: 'Tất cả' },
  { value: 'company_admin', label: 'Admin công ty' },
  { value: 'member', label: 'Thành viên' },
];

const STATUS_OPTIONS = [
  { value: '', label: 'Tất cả' },
  { value: 'true', label: 'Đang hoạt động' },
  { value: 'false', label: 'Bị vô hiệu hóa' },
];

const ROLE_COLORS = {
  company_admin: 'blue',
  member: 'default',
  super_admin: 'gold',
};

const ROLE_LABELS = {
  company_admin: 'Admin',
  member: 'Thành viên',
  super_admin: 'Super Admin',
};

export default function UserListPage() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({ page: 1, limit: 10, total: 0 });
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [roleFilter, setRoleFilter] = useState(searchParams.get('role') || '');
  const [activeFilter, setActiveFilter] = useState(searchParams.get('isActive') || '');

  const fetchUsers = async (page = 1, limit = 10) => {
    setLoading(true);
    try {
      const params = { page, limit };
      if (roleFilter) params.role = roleFilter;
      if (activeFilter) params.isActive = activeFilter;
      if (search) params.search = search;

      const res = await axiosClient.get('/admin/users', { params });
      setUsers(res.data);
      setPagination(res.pagination);
    } catch {
      // Interceptor handles error
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers(1, 10);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const params = {};
    if (roleFilter) params.role = roleFilter;
    if (activeFilter) params.isActive = activeFilter;
    if (search) params.search = search;
    setSearchParams(params, { replace: true });
  }, [roleFilter, activeFilter, search, setSearchParams]);

  const handleSearch = (value) => {
    setSearch(value);
    fetchUsers(1, pagination.limit);
  };

  const handleRoleChange = (value) => {
    setRoleFilter(value);
    setTimeout(() => fetchUsers(1, pagination.limit), 0);
  };

  const handleActiveChange = (value) => {
    setActiveFilter(value);
    setTimeout(() => fetchUsers(1, pagination.limit), 0);
  };

  const handleTableChange = (pag) => {
    fetchUsers(pag.current, pag.pageSize);
  };

  const columns = [
    {
      title: 'Người dùng',
      key: 'user',
      render: (_, record) => (
        <Space>
          <Avatar
            src={record.avatar}
            icon={!record.avatar && <UserOutlined />}
            style={{ background: record.role === 'company_admin' ? '#1890ff' : '#44C548' }}
          />
          <div>
            <Button
              type="link"
              style={{ padding: 0, fontWeight: 500, height: 'auto', lineHeight: '1.4' }}
              onClick={(e) => { e.stopPropagation(); navigate(`/users/${record._id}`); }}
            >
              {record.fullName}
            </Button>
            <div style={{ fontSize: 12, color: '#8c8c8c' }}>
              {record.email || record.phone || '—'}
            </div>
          </div>
        </Space>
      ),
    },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      width: 130,
      render: (role) => (
        <Tag
          icon={role === 'company_admin' ? <CrownOutlined /> : null}
          color={ROLE_COLORS[role]}
        >
          {ROLE_LABELS[role]}
        </Tag>
      ),
    },
    {
      title: 'Công ty',
      dataIndex: 'companyId',
      key: 'company',
      ellipsis: true,
      responsive: ['md'],
      render: (company) => company?.name ? (
        <Space size={4}>
          <span>{company.name}</span>
          {company.code && <Tag color="blue" style={{ fontSize: 11 }}>{company.code}</Tag>}
        </Space>
      ) : <span style={{ color: '#bfbfbf' }}>—</span>,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 120,
      render: (isActive) => (
        <Badge status={isActive ? 'success' : 'error'} text={isActive ? 'Hoạt động' : 'Vô hiệu'} />
      ),
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'createdAt',
      key: 'createdAt',
      width: 120,
      render: (date) => dayjs(date).format('DD/MM/YYYY'),
      responsive: ['lg'],
    },
    {
      title: '',
      key: 'action',
      width: 50,
      render: (_, record) => (
        <Button
          type="text"
          icon={<EyeOutlined />}
          onClick={(e) => { e.stopPropagation(); navigate(`/users/${record._id}`); }}
        />
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
        <Title level={4} style={{ margin: 0 }}>Quản lý người dùng</Title>
      </div>

      <Card style={{ borderRadius: 12 }} bodyStyle={{ padding: '16px 24px' }}>
        <Space style={{ marginBottom: 16, flexWrap: 'wrap' }} size={12}>
          <Input.Search
            placeholder="Tìm theo tên, email, SĐT..."
            allowClear
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onSearch={handleSearch}
            style={{ width: 280 }}
            prefix={<SearchOutlined style={{ color: '#bfbfbf' }} />}
          />
          <Select
            value={roleFilter}
            onChange={handleRoleChange}
            options={ROLE_OPTIONS}
            style={{ width: 160 }}
            placeholder="Role"
          />
          <Select
            value={activeFilter}
            onChange={handleActiveChange}
            options={STATUS_OPTIONS}
            style={{ width: 180 }}
            placeholder="Trạng thái"
          />
        </Space>

        <Table
          columns={columns}
          dataSource={users}
          rowKey="_id"
          loading={loading}
          pagination={{
            current: pagination.page,
            pageSize: pagination.limit,
            total: pagination.total,
            showSizeChanger: true,
            showTotal: (total) => `Tổng ${total} người dùng`,
          }}
          onChange={handleTableChange}
          size="middle"
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => navigate(`/users/${record._id}`),
          })}
        />
      </Card>
    </div>
  );
}
