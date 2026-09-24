import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Link, Route, Routes } from "react-router";

function Home() {
  return (
    <>
      <h1>vite-react</h1>
      <p>A Vite + React app, built by AgentCell and served as a static site.</p>
      <p>
        <Link to="/about">/about</Link> is a client-side route: no <code>about.html</code> exists.
        Load it directly or reload it, and it still works, because a site with no{" "}
        <code>404.html</code> answers unknown paths with <code>index.html</code>.
      </p>
    </>
  );
}

function About() {
  return (
    <>
      <h1>about</h1>
      <p>Rendered by react-router in the browser, from the same index.html as /.</p>
      <p>
        <Link to="/">home</Link>
      </p>
    </>
  );
}

function NotFound() {
  return (
    <>
      <h1>not found</h1>
      <p>
        The platform served index.html for this path; the router has no route for it.{" "}
        <Link to="/">home</Link>
      </p>
    </>
  );
}

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
