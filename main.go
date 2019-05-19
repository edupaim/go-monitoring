package main

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
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
	counter := prometheus.NewCounter(prometheus.CounterOpts{
		Name: "counterApp",
		Help: "Counter test",
	})
	prometheus.MustRegister(counter)
	http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		println("receive request")
		counter.Inc()
		handler := promhttp.Handler()
		handler.ServeHTTP(w, r)
	})
	if err := http.ListenAndServe(":2112", nil); err != nil {
		panic(err)
	}
}
