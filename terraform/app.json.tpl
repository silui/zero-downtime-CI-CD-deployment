[
  {
    "essential": true,
    "memory": 2046,
    "name": "django",
    "cpu": 2,
    "image": "867976228206.dkr.ecr.us-west-1.amazonaws.com/django-app:1",
    "workingDirectory": "/code",
    "command": ["python","/code/cowork_space/manage.py","runserver","0:8000"],
    "portMappings": [
        {
            "containerPort": 8000,
            "hostPort": 80
        }
    ]
  }
]

