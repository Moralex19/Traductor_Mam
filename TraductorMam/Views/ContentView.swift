import SwiftUI
#if canImport(Translation)
import Translation
#endif

struct ContentView: View {
    @StateObject private var vm = TraductorViewModel()
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    private func isCompactWidth(_ width: CGFloat) -> Bool { width < 500 }

    private func headerHeight(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 120 : 150
    }

    private func titleFontSize(for width: CGFloat) -> CGFloat {
        if width >= 900 { return 44 }
        if isCompactWidth(width) { return 30 }
        return 36
    }

    private func translateButtonFontSize(for width: CGFloat) -> CGFloat {
        if width >= 900 { return 32 }
        if isCompactWidth(width) { return 24 }
        return 28
    }

    private func inputFontSize(for width: CGFloat) -> CGFloat {
        if width >= 900 { return 26 }
        if isCompactWidth(width) { return 20 }
        return 24
    }

    private func outputFontSize(for width: CGFloat) -> CGFloat {
        if width >= 900 { return 26 }
        if isCompactWidth(width) { return 20 }
        return 24
    }

    private func contentMaxWidth(for width: CGFloat) -> CGFloat {
        if width >= 1024 { return 920 }
        if width >= 834 { return 820 }
        return 700
    }

    private func contentHorizontalPadding(for width: CGFloat) -> CGFloat {
        if width >= 834 { return 28 }
        return 16
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.mint)
                    .frame(height: headerHeight(for: width))
                    .overlay(
                        ZStack {
                            Text("Traductor Mam")
                                .font(.custom("MarkerFelt-Wide", size: titleFontSize(for: width)))
                                .foregroundColor(.white)

                            HStack {
                                Spacer()
                                Button(action: { vm.mostrarMenu = true }) {
                                    Image(systemName: "sidebar.left")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal)
                        }
                    )

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 16)

                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Escribe aquí...", text: $vm.textoDeEntrada)
                                .font(.custom("ChalkboardSE-Regular", size: inputFontSize(for: width)))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        .onChange(of: vm.textoDeEntrada) {
                            vm.actualizarSugerencias()
                        }

                        if !vm.sugerencias.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(vm.sugerencias, id: \.self) { sugerencia in
                                    Button {
                                        vm.seleccionarSugerencia(sugerencia)
                                    } label: {
                                        Text(sugerencia)
                                            .font(.custom("ChalkboardSE-Regular", size: inputFontSize(for: width)))
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Picker("Idioma de entrada", selection: $vm.idiomaDeEntradaSeleccionado) {
                            ForEach(vm.idiomasDeEntrada) { idioma in
                                Text(idioma.rawValue).tag(idioma)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: vm.idiomaDeEntradaSeleccionado) {
                            vm.actualizarSugerencias()
                        }

                        Picker("Idioma de destino", selection: $vm.idiomaDestinoSeleccionado) {
                            ForEach(vm.idiomasDestino) { idioma in
                                Text(idioma.rawValue).tag(idioma)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        Button {
                            vm.traducirSegunSeleccion()
                        } label: {
                            Text("Traducir")
                                .font(.custom("MarkerFelt-Wide", size: translateButtonFontSize(for: width)))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.mint)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        ZStack(alignment: .bottomTrailing) {
                            Text(vm.textoTraducido)
                                .font(.custom("ChalkboardSE-Regular", size: outputFontSize(for: width)))
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                                .padding()
                                .padding(.trailing, 96)
                                .padding(.bottom, 56)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            
                            HStack(spacing: 8) {
                                Button {
                                    vm.copiarTextoTraducido()
                                } label: {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.mint)
                                        .padding(10)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .accessibilityLabel("Copiar traducción")
                                .disabled(vm.textoTraducido.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Button {
                                    vm.reproducirSegunIdiomaDestino()
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.mint)
                                        .padding(10)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .accessibilityLabel("Reproducir traducción")
                                .disabled(vm.textoTraducido.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .padding(10)
                        }
                        .padding(.horizontal)

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, contentHorizontalPadding(for: width))
                    .frame(maxWidth: contentMaxWidth(for: width))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $vm.mostrarMenu) {
            MenuSheetView(
                mostrarInfo: $vm.mostrarInfo,
                mostrarCreditos: $vm.mostrarCreditos
            )
        }

        #if canImport(Translation)
        .translationTask(vm.appleConfig) { session in
            do {
                let response = try await session.translate(vm.applePendingText)
                vm.aplicarResultadoAppleTranslation(response.targetText)
            } catch {
                vm.aplicarFallbackAppleTranslation()
            }
        }
        #endif
    }
}

#Preview {
    ContentView()
}

