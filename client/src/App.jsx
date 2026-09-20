import { useState } from "react";
import { handleFileChange } from "./handlers/handleFileChange";
import { handleSubmit } from "./handlers/handleSubmit";

function App() {
  const [file, setFile] = useState(null);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const onFileChange = (event) => {
    handleFileChange(event, setFile, setError);
  };

  const onSubmit = async (event) => {
    await handleSubmit({
      event,
      file,
      setLoading,
      setError,
      setResult,
    });
  };

  return (
    <div
      style={{
        maxWidth: "620px",
        margin: "60px auto",
        padding: "32px 24px",
        fontFamily: "sans-serif",
        background: "#ffffff",
        border: "1px solid #e5e7eb",
        borderRadius: "16px",
        boxShadow: "0 8px 24px rgba(15, 23, 42, 0.08)",
      }}
    >
      <h2
        style={{
          margin: "0 0 24px",
          fontSize: "2rem",
          textAlign: "center",
          color: "#111827",
        }}
      >
        SoundScan Analyzer
      </h2>

      <form onSubmit={onSubmit} style={{ width: "100%" }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "12px",
            width: "100%",
            marginBottom: "18px",
          }}
        >
          <input
            type="file"
            accept=".mp3"
            onChange={onFileChange}
            style={{
              flex: 1,
              minWidth: 0,
              padding: "12px 14px",
              border: "1px solid #d1d5db",
              borderRadius: "10px",
              background: "#f9fafb",
              fontSize: "0.95rem",
            }}
          />

          <button
            type="submit"
            disabled={loading}
            style={{
              minWidth: "150px",
              padding: "12px 20px",
              border: "none",
              borderRadius: "10px",
              background: loading ? "#9ca3af" : "#2563eb",
              color: "#ffffff",
              fontWeight: "600",
              fontSize: "0.95rem",
              cursor: loading ? "not-allowed" : "pointer",
            }}
          >
            {loading ? "Analyzing..." : "Submit"}
          </button>
        </div>
      </form>

      <div
        style={{
          minHeight: "140px",
          padding: "18px",
          background: "#f8fafc",
          border: "1px solid #e2e8f0",
          borderRadius: "12px",
          color: "#1f2937",
        }}
      >
        {error && <p style={{ margin: 0, color: "#dc2626", fontWeight: 500 }}>{error}</p>}

        {!error && !result && (
          <p style={{ margin: 0, color: "#6b7280" }}>Your analysis response will appear here.</p>
        )}

        {result && (
          <div>
            <h3 style={{ margin: "0 0 12px", fontSize: "1.1rem" }}>Response</h3>
            <pre
              style={{
                margin: 0,
                whiteSpace: "pre-wrap",
                wordBreak: "break-word",
                fontSize: "0.88rem",
                lineHeight: 1.6,
                color: "#111827",
                background: "#ffffff",
                border: "1px solid #e5e7eb",
                borderRadius: "8px",
                padding: "12px",
              }}
            >
              {JSON.stringify(result, null, 2)}
            </pre>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
