//line_chart for balance of users over time
let renderChart = function(chart_data) {

        let ctx = document.getElementById('canvas').getContext('2d');
        var datasetValue =[];
        for (var j=0; j<17; j++) {
            datasetValue[j] = {
                //fillColor: 'rgba(220,220,220,0.5)',
                // strokeColor :'rgba(220,220,220,1)',
                label: "User "+j,
                borderColor: getRandomColor(),
                //backgroundColor: getRandomColor(),
                fill: false,
                bezierCurve : false,
                lineTension: 0,
                data: data['user'+j]
            }
        }
        window.my_chart = new Chart(ctx, {
          type: 'line',
          data: {
            labels: chart_data["user\\day"],
            datasets: datasetValue
          },
          options: {
            responsive: true,
            legend: {
              position: 'top'
            },
            title: {
              display: true,
              text: 'Bmx bot data analysis for balance of users over time'
            },
            scales: {
              yAxes: [{
                scaleLabel: {
                  display: true,
                  labelString: 'Balance of users'
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
        url: "https://raw.githubusercontent.com/bugmark/outreachy/master/datafiles/parse_balance_log.csv",
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
