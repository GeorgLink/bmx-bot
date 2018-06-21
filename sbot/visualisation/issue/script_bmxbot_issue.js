//line_chart for number of open and closed issues' progress in each run
let renderChart = function(chart_data) {

        let ctx = document.getElementById('canvas').getContext('2d');

        window.my_chart = new Chart(ctx, {
          type: 'line',
          data: {
            labels: chart_data["days"],
            datasets: [

              {
                label: "Issues created in a day",
                borderColor: getRandomColor(),
                //pointBackgroundColor: getRandomColor(),
                fill: false,
                data: data["open issues at the end of a day"]
              },
              {
                label: "Closed issues at the end of a day",
                borderColor: getRandomColor(),
                fill: false,
                data: data["closed issues at the end of a day"]
              }


            ]
          },
          options: {
            responsive: true,
            legend: {
              position: 'top'
            },
            title: {
              display: true,
              text: 'Bmx run bot data analysis for issues created and closed per day'
            },
            scales: {
              yAxes: [{
                scaleLabel: {
                  display: true,
                  labelString: '# of Issues'
                }
              }],
              xAxes: [{
                scaleLabel: {
                  display: true,
                  labelString: 'Day #'
                }
              }]
            }
          }
        });
      }

      let getRandomColor = function() {
        let letters = '0123456789ABCDEF'.split('')
        let color = '#'
        for (let i = 0; i < 6; i++) {
          color += letters[Math.floor(Math.random() * 16)]
        }
        return color
      }

    $(document).ready(function() {

      $.ajax({
        url: "https://gist.githubusercontent.com/snehasi/9929934318d879d3e92cae14769e1473/raw/95279c34e16e552aea4002604193c30ff3ec8f60/health_issues.csv",
        async: false,
        success: function(csv) {
          data = {}

          for (let line of csv.split("\n"))
          {
            let arr = line.split(",");
            if (arr.length > 1)
            {
              data[arr[0]] = arr.slice(1).map(Number);
            }
          }

          renderChart(data);
        }
      });
    });
