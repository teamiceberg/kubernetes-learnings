FROM python:3.13-slim



# Install only what you need
RUN pip install --no-cache-dir \
    torch torchvision \
    transformers \
    flask \
    numpy

# Copy your inference app
COPY sentiment-analysis-app.py /app/app.py
WORKDIR /app

# Declare the listening port
EXPOSE 5080

# Start the Flask app
CMD ["python", "app.py"]
