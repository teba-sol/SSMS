const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Ensure 'pg' package is installed
try {
  require.resolve('pg');
} catch (e) {
  console.log('Installing pg package for database connection...');
  execSync('npm install pg --no-save', { stdio: 'inherit' });
}

const { Client } = require('pg');

// Read database URL from command line arguments or environment
const dbUrl = process.argv[2] || process.env.DATABASE_URL;

if (!dbUrl) {
  console.error('\nError: Database connection string is required.');
  console.log('\nUsage:');
  console.log('  node deploy.js "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"');
  console.log('\nYou can find this URI in your Supabase Dashboard:');
  console.log('  Settings > Database > Connection string > URI');
  process.exit(1);
}

const sqlPath = path.join(__dirname, 'setup_all.sql');
if (!fs.existsSync(sqlPath)) {
  console.error(`Error: SQL setup file not found at ${sqlPath}`);
  process.exit(1);
}

const sql = fs.readFileSync(sqlPath, 'utf8');

console.log('Connecting to Supabase Database...');
const client = new Client({
  connectionString: dbUrl,
  ssl: {
    rejectUnauthorized: false
  }
});

async function run() {
  try {
    await client.connect();
    console.log('Connected successfully. Running database setup script (this may take a few seconds)...');
    
    // Execute the complete setup script
    await client.query(sql);
    
    console.log('\nSUCCESS: Database tables, enums, triggers, and seed data created successfully!');
    console.log('You can now log in with:');
    console.log('  Email:    admin@sscs.com');
    console.log('  Password: Admin@12345');
  } catch (err) {
    console.error('\nDatabase execution failed with error:', err.message);
    if (err.detail) console.error('Details:', err.detail);
    if (err.hint) console.error('Hint:', err.hint);
  } finally {
    await client.end();
  }
}

run();
