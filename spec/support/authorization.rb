# frozen_string_literal: true

# Set up a root user so we can set up authentication on a database level.
MONGOID_ROOT_USER = Mongo::Auth::User.new(
  database: Mongo::Database::ADMIN,
  user: 'active_document-user',
  password: 'password',
  roles: [
    Mongo::Auth::Roles::USER_ADMIN_ANY_DATABASE,
    Mongo::Auth::Roles::DATABASE_ADMIN_ANY_DATABASE,
    Mongo::Auth::Roles::READ_WRITE_ANY_DATABASE,
    Mongo::Auth::Roles::HOST_MANAGER,
    Mongo::Auth::Roles::CLUSTER_MONITOR
  ]
)
