# Use the official Python image from the Docker Hub
FROM python:3.7-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port 80 available to the world outside this container
EXPOSE 80

# Run main.py when the container launches
CMD ["python", "main.py", "--prune_type=lt", "--arch_type=fc1", "--dataset=mnist", "--prune_percent=10", "--prune_iterations=35"]
