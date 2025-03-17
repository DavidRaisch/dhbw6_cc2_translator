# Dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your app's source code
COPY . .

EXPOSE 5005

# Use Gunicorn as the WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "wsgi:app"]
