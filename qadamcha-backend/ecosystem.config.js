module.exports = {
    apps: [{
        name: 'qadamcha-backend',
        script: 'src/app.js',
        instances: 'max',
        exec_mode: 'cluster',
        autorestart: true,
        watch: false,
        max_memory_restart: '512M',
        env: {
            NODE_ENV: 'development',
            PORT: 3000
        },
        env_production: {
            NODE_ENV: 'production',
            PORT: 3000
        },
        // Loglar
        log_date_format: 'YYYY-MM-DD HH:mm:ss',
        error_file: 'logs/error.log',
        out_file: 'logs/app.log',
        merge_logs: true,

        // Cluster mode da graceful restart
        listen_timeout: 5000,
        kill_timeout: 5000,
    }]
};
