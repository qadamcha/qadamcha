require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');

const promoteUser = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB connected');

        const phone = '+998998878079';
        const user = await User.findOne({ phone });

        if (!user) {
            console.log('User not found!');
            process.exit(1);
        }

        await User.updateOne({ _id: user._id }, { $set: { role: 'admin' } });

        console.log(`Success! User ${phone} is now an ADMIN.`);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

promoteUser();
