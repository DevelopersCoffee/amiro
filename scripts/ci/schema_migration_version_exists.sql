select 1
from supabase_migrations.schema_migrations
where version = :'migration_version'
limit 1;
