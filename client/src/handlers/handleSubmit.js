export const handleSubmit = async ({ event, file, setLoading, setError, setResult }) => {
  event.preventDefault();

  if (!file) {
    setError("Please select an MP3 file first.");
    return;
  }

  setLoading(true);
  setError(null);
  setResult(null);

  const formData = new FormData();
  formData.append("audio", file);

  try {
    const response = await fetch("http://localhost:3000/api/upload", {
      method: "POST",
      body: formData,
    });

    const data = await response.json().catch(() => null);

    if (!response.ok || data?.success === false) {
      throw new Error(data?.error || `Server error: ${response.status}`);
    }

    setResult(data?.result ?? data);
  } catch (err) {
    setError(err.message);
  } finally {
    setLoading(false);
  }
};
