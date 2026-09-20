export const handleFileChange = (event, setFile, setError) => {
  const selectedFile = event.target.files[0];
  setFile(selectedFile);
  setError(null);
};
