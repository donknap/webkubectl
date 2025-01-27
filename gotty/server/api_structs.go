package server

type ApiResponse struct {
	Success bool   `json:"success"`
	Token   string `json:"token"`
	Message string `json:"message"`
}

type KubeConfigRequest struct {
	Name         string `json:"name"`
	KubeConfig   string `json:"kubeConfig"`
	ExtendParams string `json:"extendParams"`
}

type KubeTokenRequest struct {
	Name         string `json:"name"`
	ApiServer    string `json:"apiServer"`
	Token        string `json:"token"`
	ExtendParams string `json:"extendParams"`
}
