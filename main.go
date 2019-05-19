package main

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/client_golang/prometheus/push"
	"net/http"
)

func main() {
	println("starting server...")
	prometheus.MustRegister(prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "version",
		Help: "Version information about this service",
		ConstLabels: map[string]string{
			"version": Version,
			"service": ApplicationName,
		},
	}))
	// Easy case:
	counter := prometheus.NewCounter(prometheus.CounterOpts{
		Name: "counter_app",
		Help: "Counter test",
	})
	prometheus.MustRegister(counter)
	http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		counter.Inc()
		err := push.New("http://pushgateway:9091", "demo_service").
			Collector(counter).
			Push()
		if err != nil {
			panic(err)
		}
		handler := promhttp.Handler()
		handler.ServeHTTP(w, r)
	})
	if err := http.ListenAndServe(":2112", nil); err != nil {
		panic(err)
	}
}
