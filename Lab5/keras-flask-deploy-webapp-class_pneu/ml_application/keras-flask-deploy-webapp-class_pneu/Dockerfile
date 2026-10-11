FROM python:3.10-slim

# Show print() output in "docker logs" immediately
ENV PYTHONUNBUFFERED=1

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies (tensorflow-cpu is included in req_info.txt)
COPY req_info.txt ./

RUN pip install --no-cache-dir -r req_info.txt

# Bundle app source
COPY app_pneu.py util.py ./
COPY templates/ templates/
COPY static/ static/

# Bundle the models (choose one at run time with -e MODEL_PATH=...)
COPY keras_model_trained/ keras_model_trained/
COPY keras_model_untrained/ keras_model_untrained/

# Folder where the app saves the uploaded image
RUN mkdir uploads

EXPOSE 5000
CMD [ "python", "app_pneu.py" ]
