import React, { useState } from "react";
import { TextField, Button, Container, Typography } from "@mui/material";
import axios from "axios";

function LoginForm() {
  const [firstname, setFirstname] = useState("");
  const [lastname, setLastname] = useState("");
  const [mobile, setMobile] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  // Make handleSubmit async
  const handleSubmit = async (event) => {
    event.preventDefault();

    // Validate form inputs
    const validType = /^[0-9\b]+$/;
    if (validType.test(mobile) === false) {
      alert("Please enter a valid mobile number");
      return;
    }

    // Prepare data to be sent to the backend
    const userData = {
      firstname,
      lastname,
      mobile,
      username,
      password,
    };

    try {
      // Send a POST request to the backend
      const response = await axios.post("http://localhost:5000/signup", userData);
      console.log(response.data.message); // Log success message or display it in UI

      // Reset form after successful submission
      setFirstname("");
      setLastname("");
      setMobile("");
      setUsername("");
      setPassword("");
    } catch (error) {
      console.error("Error saving user:", error);
      alert("Failed to register user.");
    }
  };

  return (
    <Container maxWidth="xs">
      <Typography variant="h4" component="h1" gutterBottom>
        Who are You!
      </Typography>
      <form onSubmit={handleSubmit}>
        <TextField
          label="First Name"
          required
          variant="outlined"
          fullWidth
          margin="normal"
          value={firstname}
          onChange={(e) => setFirstname(e.target.value)}
        />
        <TextField
          label="Last Name"
          required
          variant="outlined"
          fullWidth
          margin="normal"
          value={lastname}
          onChange={(e) => setLastname(e.target.value)}
        />
        <TextField
          label="Mobile Number"
          required
          variant="outlined"
          fullWidth
          margin="normal"
          value={mobile}
          onChange={(e) => setMobile(e.target.value)}
        />
        <TextField
          label="Username"
          variant="outlined"
          required
          fullWidth
          margin="normal"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
        <TextField
          label="Password"
          required
          variant="outlined"
          fullWidth
          margin="normal"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <Button variant="contained" color="primary" type="submit" fullWidth>
          Sign Up
        </Button>
      </form>
    </Container>
  );
}

export default LoginForm;
