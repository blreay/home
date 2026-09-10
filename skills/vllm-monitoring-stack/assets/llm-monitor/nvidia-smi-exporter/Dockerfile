FROM python:3.11-slim
COPY nvidia_smi_exporter.py /opt/nvidia_smi_exporter.py
EXPOSE 9835
ENTRYPOINT ["python3", "/opt/nvidia_smi_exporter.py"]
