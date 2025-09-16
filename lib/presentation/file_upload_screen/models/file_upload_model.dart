class FileUploadModel {
  String? fileName;
  int? fileSize;
  String? filePath;
  bool isUploading;
  String? uploadProgress;
  String? errorMessage;

  FileUploadModel({
    this.fileName,
    this.fileSize,
    this.filePath,
    this.isUploading = false,
    this.uploadProgress,
    this.errorMessage,
  });

  FileUploadModel copyWith({
    String? fileName,
    int? fileSize,
    String? filePath,
    bool? isUploading,
    String? uploadProgress,
    String? errorMessage,
  }) {
    return FileUploadModel(
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'filePath': filePath,
      'isUploading': isUploading,
      'uploadProgress': uploadProgress,
      'errorMessage': errorMessage,
    };
  }

  factory FileUploadModel.fromJson(Map<String, dynamic> json) {
    return FileUploadModel(
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      filePath: json['filePath'],
      isUploading: json['isUploading'] ?? false,
      uploadProgress: json['uploadProgress'],
      errorMessage: json['errorMessage'],
    );
  }
}
