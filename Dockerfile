# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set environment variables
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirement.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirement.txt

# Copy the current directory contents into the container at /app
COPY . .

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV MONGODB_URI=mongodb://localhost:27017/

# Run app.py when the container launches
CMD ["flask", "run","--host=0.0.0.0" ]

