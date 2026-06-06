import axios from "axios";

export const API_TOKEN_KEY = "admin_token";

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:5000/api",
});

function getCookieToken() {
  const tokenCookie = document.cookie
    .split("; ")
    .find((cookie) => cookie.startsWith(`${API_TOKEN_KEY}=`));

  return tokenCookie ? decodeURIComponent(tokenCookie.split("=")[1]) : null;
}

api.interceptors.request.use((config) => {
  if (typeof window !== "undefined") {
    const token = window.localStorage.getItem(API_TOKEN_KEY) || getCookieToken();
    if (token) {
      window.localStorage.setItem(API_TOKEN_KEY, token);
      config.headers.Authorization = `Bearer ${token}`;
    }
  }

  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (
      typeof window !== "undefined" &&
      (error.response?.status === 401 || error.response?.status === 403)
    ) {
      window.localStorage.removeItem(API_TOKEN_KEY);
      document.cookie = `${API_TOKEN_KEY}=; path=/; max-age=0`;

      if (window.location.pathname !== "/admin/login") {
        window.location.href = "/admin/login";
      }
    }

    return Promise.reject(error);
  }
);

export default api;
