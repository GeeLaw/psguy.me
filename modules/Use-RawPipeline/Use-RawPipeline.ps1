$script:ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue;
Try
{
    Add-Type -TypeDefinition '
        namespace PSGuy.UseRawPipeline
        {
            public sealed class RawPipelineObject : System.IDisposable
            {
                private void ThrowIfDisposed()
                {
                    if (disposed)
                        throw new System.ObjectDisposedException("This RawPipelineObject has been disposed.");
                }

                private string fileName;
                private bool owner;
                private bool disposed = false;

                public string GetFileName()
                {
                    ThrowIfDisposed();
                    return fileName;
                }
                public bool IsOwner()
                {
                    return owner;
                }
                public RawPipelineObject(string fileName) { owner = false; this.fileName = fileName; }
                public RawPipelineObject() { owner = true; this.fileName = System.IO.Path.GetTempFileName(); }

                static System.Text.Encoding preferredEncoding = null;
                public static System.Text.Encoding PreferredEncoding
                {
                    get { return preferredEncoding; }
                    set { preferredEncoding = value; }
                }

                static bool detectEncodingFromBom = true;
                public static bool DetectEncodingFromBom
                {
                    get { return detectEncodingFromBom; }
                    set { detectEncodingFromBom = true; }
                }

                public static implicit operator string (RawPipelineObject obj)
                {
                    return object.ReferenceEquals(obj, null)
                        ? string.Empty
                        : obj.GetContent();
                }

                public static implicit operator RawPipelineObject (string fileName)
                {
                    return string.IsNullOrWhiteSpace(fileName)
                        ? null
                        : new RawPipelineObject(fileName);
                }

                public string GetContent()
                {
                    ThrowIfDisposed();
                    using (var sr = object.ReferenceEquals(preferredEncoding, null)
                        ? new System.IO.StreamReader(fileName, detectEncodingFromBom)
                        : new System.IO.StreamReader(fileName, preferredEncoding, detectEncodingFromBom))
                        return sr.ReadToEnd();
                }

                public override string ToString()
                {
                    return GetContent();
                }

                public void Dispose()
                {
                    if (disposed)
                        return;
                    disposed = true;
                    if (owner)
                    {
                        try { System.IO.File.Delete(fileName); }
                        catch { }
                    }
                    owner = false;
                    fileName = null;
                }
                ~RawPipelineObject()
                {
                    Dispose();
                }
            }
        }
    ' -Language 'CSharp';
}
Catch { }
