import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import bodyParser from 'body-parser';

// Initialize Express
const app = express();

// Use Middleware
app.use(cors());
app.use(bodyParser.json());

// Connect to MongoDB (Replace with your MongoDB connection string)
mongoose.connect('mongodb://localhost:27017/mydatabase')
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.log(err));

// Create Mongoose Schema for Users
const userSchema = new mongoose.Schema({
  firstname: String,
  lastname: String,
  mobile: String,
  username: String,
  password: String,
});

// Create User model from Schema
const User = mongoose.model('User', userSchema);

// Route to handle form submission from React
app.post('/signup', async (req, res) => {
  const { firstname, lastname, mobile, username, password } = req.body;

  try {
    const newUser = new User({
      firstname,
      lastname,
      mobile,
      username,
      password,
    });

    // Save user to MongoDB
    await newUser.save();

    res.status(201).json({ message: 'User registered successfully!' });
  } catch (error) {
    res.status(500).json({ message: 'Error saving user' });
  }
});

// Start the server
const PORT = 5000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
