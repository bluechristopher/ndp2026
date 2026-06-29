from flask import Flask, render_template, request
import csv
from datetime import datetime

app = Flask(__name__)


@app.route("/", methods=["GET", "POST"])
def home():
    if request.method == "POST":
        name = request.form["name"]
        message = request.form["message"]
        curr_datetime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Write data into CSV
        # File closes after the with block
        with open("wishes.csv", "a", newline="", encoding="utf-8") as file:
            writer = csv.writer(file)
            writer.writerow([curr_datetime, name, message])
    
    # Read data and display
    wishes = []  # store wishes
    
    # File closes after the with block
    with open("wishes.csv", "r", newline="", encoding="utf-8") as file:
        reader = csv.reader(file)
        next(reader)  # Skip header row
        for row in reader:
            wishes.append(row)
        
        wishes.reverse()  # reverse list of wishes to show latest first
        return render_template("index.html", wishes=wishes)


if __name__ == "__main__":
    app.run()