# National Day 2026 Wish Page
This Flask web app serves a simple National Day wish page where users can submit their wishes for Singapore’s 61st birthday.

## Deployment Guide
Deploying a Flask web application allows users to access it via the Internet. There are several ways to deploy a Flask application on AWS. Two approaches include:

- Deploying using Elastic Beanstalk – AWS automatically provisions and manages the underlying infrastructure, allowing you to focus primarily on developing and deploying your application.
- Deploying on an EC2 instance – You provision and manage your own virtual server, giving you complete control over the operating system and software configuration.


## AWS Elastic Beanstalk
Elastic Beanstalk is a Platform as a Service (PaaS) offered by AWS. It allows developers to deploy web applications without having to manually configure or manage the underlying servers.

When you upload your Flask application, Elastic Beanstalk automatically provisions the required AWS resources, deploys your application, and manages the runtime environment.

Although your application still runs on EC2 instances behind the scenes, Elastic Beanstalk takes care of the server setup and ongoing management for you.

### Step 1: Create a `requirements.txt` file
```
Flask>=3.1.2
gunicorn>=26.0.0
```

### Step 2: Select all the project files and compress them into a ZIP file. The project files should appear immediately inside the ZIP file.

### Step 3: Open Elastic Beanstalk in AWS Console.

### Step 4: Create an Environment.
- Select an application name
- Under Platform details, select Python. For the application code, choose to upload a Local file, where you will upload the zip file created.
- Under 'Platform-specific options', WSGI path must be updated to `app:app`. This tells Gunicorn how to locate your Flask app. In this case, it will locate `app.py` and look for `app = Flask(__name__)`. If you are using `main.py` instead, then you should specify it as `main:app`.
- When you are using the AWS Academy Learner Lab, you have to specify, under Service access, that the Service role is `LabRole`, and the EC2 instance profile is `LabInstanceProfile`. These roles already contain the permissions required for the lab exercises, so selecting them allows Elastic Beanstalk to deploy and manage your Flask application successfully.
- Press 'Create' button at the bottom.

### Step 5: A message will be shown: "Elastic Beanstalk is launching your environment. This will take a few minutes." You can see the process under 'Events'. After a while, you will see a URL appear under 'Domain' in 'Environment overview'. Click on that to view the deployed web app.


## AWS EC2

For your convenience, there is an automation script (`setup.sh`) included for your to deploy a Flask web app  onto an Ubuntu EC2 instance within the AWS Academy Learner Lab environment.

### Architectural Overview
Instead of running a fragile development server, the deployment architecture is structured for production resiliency:

* **Nginx:** Acts as the reverse proxy facing the public internet on Port 80. It handles incoming web traffic dynamically, regardless of IP changes.
* **Gunicorn:** Functions as the WSGI server, running background worker processes to handle concurrent user requests.
* **Systemd Service (`ndp-app`):** Manages the Gunicorn process as a native background system service, ensuring the application automatically spins up whenever the EC2 server boots.

---

### Step 1: Launch and Configure the EC2 Instance

1. Log in to your **AWS Academy Learner Lab** console and click **Start Lab**. Once the status dot turns green, click the **AWS** link to open the Management Console.
2. Search for **EC2** in the top search bar and click **Launch instance**.
3. Configure the instance details exactly as follows:
   * **Name:** `ndp-app`
   * **Application and OS Images (AMI):** Select **Ubuntu**.
   * **Instance Type:** Select `t3.micro`.
   * **Key Pair:** Select **Proceed without a key pair (Not recommended)**. *Note: We will use AWS's secure browser terminal instead.*
   * **Network Settings:** Ensure **Assign public IP** is set to **Enable**. Select **Create security group** and check the boxes to allow **SSH traffic** and **HTTP traffic from the internet**.
4. Click **Launch instance** at the bottom of the page.

---

### Step 2: Connect to the Server

1. From your AWS EC2 dashboard, click **Instances (running)**.
2. Select your newly created `ndp-app` instance by checking the box next to it.
3. Click the **Connect** button at the top right of the dashboard screen.
4. Choose the **EC2 Instance Connect** tab, leave the username as `ubuntu`, and click **Connect**. 
5. A new browser tab will open, presenting you with a live Linux command-line terminal logged straight into your server.

---

### Step 3: Run the Automated Deployment

Once your browser terminal loads up, copy and paste the following three commands to pull your code and run the automated pipeline:

```bash
git clone https://github.com/bluechristopher/ndp2026.git
cd ndp2026
chmod +x setup.sh
./setup.sh
```

#### What the Script Automates Behind the Scenes
- System Provisioning: Updates Ubuntu package registries and installs python3-venv, pip, git, and nginx.
- Environment Isolation: Provisions an isolated Python virtual environment (venv) and installs flask and gunicorn.
- Permissions Configuration: Binds the Nginx system user to the ubuntu group security profile so it can communicate safely with the backend code.
- Process Automation: Generates and activates the background system manager service (ndp-app.service).
- Reverse Proxy Mapping: Standardizes routing parameters through an Nginx structural configuration set up with an IP wildcard catch-all (_) so that the application safely survives mandatory AWS Academy lab reboots.

### Step 4: Access Your Web App
Copy the public IPv4 address of your instance from the AWS EC2 dashboard, open a new web browser tab, and navigate straight to http://YOUR_EC2_PUBLIC_IP
(No port numbers are required at the end of the URL because Nginx routes everything over standard web port 80).

---

![NDP Logo](https://isomer-user-content.by.gov.sg/84/32bc5152-fec6-4787-a6ff-cf8bcd343bda/NDP_61_Logo_Full_Gradient.png)
