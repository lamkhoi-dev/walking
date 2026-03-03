import { useState, useEffect } from 'react';
import { Table, Card, Tag, Input, Select, Space, Typography, Button } from 'antd';
import { SearchOutlined, EyeOutlined } from '@ant-design/icons';
import { useNavigate, useSearchParams } from 'react-router-dom';
import axiosClient from '../api/axiosClient';
import dayjs from 'dayjs';

const { Title } = Typography;

const STATUS_OPTIONS = [
  { value: '', label: 'Tất cả' },
  { value: 'pending', label: 'Chờ duyệt' },
  { value: 'approved', label: 'Đã duyệt' },
  { value: 'rejected', label: 'Bị từ chối' },
  { value: 'suspended', label: 'Tạm ngưng' },
];

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

export default function CompanyListPage() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const [companies, setCompanies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({ page: 1, limit: 10, total: 0 });
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [statusFilter, setStatusFilter] = useState(searchParams.get('status') || '');

  const fetchCompanies = async (page = 1, limit = 10, status = statusFilter, searchText = search) => {
    setLoading(true);
    try {
      const params = { page, limit };
      if (status) params.status = status;
      if (searchText) params.search = searchText;

      const res = await axiosClient.get('/admin/companies', { params });
      setCompanies(res.data);
      setPagination(res.pagination);
    } catch {
      // Interceptor handles error
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCompanies(1, 10, statusFilter, search);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Sync URL params on filter change
  useEffect(() => {
    const params = {};
    if (statusFilter) params.status = statusFilter;
    if (search) params.search = search;
    setSearchParams(params, { replace: true });
  }, [statusFilter, search, setSearchParams]);

  const handleSearch = (value) => {
    setSearch(value);
    fetchCompanies(1, pagination.limit, statusFilter, value);
  };

  const handleStatusChange = (value) => {
    setStatusFilter(value);
    fetchCompanies(1, pagination.limit, value, search);
  };

  const handleTableChange = (pag) => {
    fetchCompanies(pag.current, pag.pageSize, statusFilter, search);
  };

  const columns = [
    {
      title: 'Tên công ty',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      render: (text, record) => (
        <Button
          type="link"
          style={{ padding: 0, fontWeight: 500 }}
          onClick={() => navigate(`/companies/${record._id}`)}
        >
          {text}
        </Button>
      ),
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      ellipsis: true,
      responsive: ['md'],
    },
    {
      title: 'Admin',
      dataIndex: ['adminId', 'fullName'],
      key: 'admin',
      ellipsis: true,
      responsive: ['lg'],
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 130,
      render: (status) => (
        <Tag color={STATUS_COLORS[status]}>{STATUS_LABELS[status]}</Tag>
      ),
    },
    {
      title: 'Mã công ty',
      dataIndex: 'code',
      key: 'code',
      width: 110,
      render: (code) => code ? <Tag color="blue">{code}</Tag> : '—',
      responsive: ['lg'],
    },
    {
      title: 'Ngày đăng ký',
      dataIndex: 'createdAt',
      key: 'createdAt',
      width: 130,
      render: (date) => dayjs(date).format('DD/MM/YYYY'),
      responsive: ['md'],
    },
    {
      title: '',
      key: 'action',
      width: 50,
      render: (_, record) => (
        <Button
          type="text"
          icon={<EyeOutlined />}
          onClick={() => navigate(`/companies/${record._id}`)}
        />
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
        <Title level={4} style={{ margin: 0 }}>Quản lý công ty</Title>
      </div>

      <Card style={{ borderRadius: 12 }} bodyStyle={{ padding: '16px 24px' }}>
        {/* Filters */}
        <Space style={{ marginBottom: 16, flexWrap: 'wrap' }} size={12}>
          <Input.Search
            placeholder="Tìm theo tên công ty..."
            allowClear
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onSearch={handleSearch}
            style={{ width: 280 }}
            prefix={<SearchOutlined style={{ color: '#bfbfbf' }} />}
          />
          <Select
            value={statusFilter}
            onChange={handleStatusChange}
            options={STATUS_OPTIONS}
            style={{ width: 160 }}
            placeholder="Trạng thái"
          />
        </Space>

        {/* Table */}
        <Table
          columns={columns}
          dataSource={companies}
          rowKey="_id"
          loading={loading}
          pagination={{
            current: pagination.page,
            pageSize: pagination.limit,
            total: pagination.total,
            showSizeChanger: true,
            showTotal: (total) => `Tổng ${total} công ty`,
          }}
          onChange={handleTableChange}
          size="middle"
          onRow={(record) => ({
            style: { cursor: 'pointer' },
            onClick: () => navigate(`/companies/${record._id}`),
          })}
        />
      </Card>
    </div>
  );
}
