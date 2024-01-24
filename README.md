# TekPort
The program is designed to demonstrate the control of Tektronix oscilloscopes via the RPC protocol with Ethernet port.
Just run TekPort.exe. Don't require any installation

Программа предназначена для демонстрации управления осциллографами Tektronix посредством протокола RPC через Ethernet порт.
The program is designed to demonstrate the control of Tektronix oscilloscopes via the RPC protocol with Ethernet port.
При использовании надо запустить TekPort.exe . 
Run TekPort.exe
  В открывшемся окне замените IP адрес на путь к вашему осциллографу. IP адрес или имя хоста в вашей сети.
  In the window that opens, replace the IP address with the path to your oscilloscope. The IP address or host name on your network.
  Нажмите GetPort. В поле Port должен появится номер порта для связи по протоколу RPC.
  Click getPort. The port number for RPC communication should appear in the Port field.
  Нажмите Connect. Будет сделана попытка установить связь с регистратором. В поле memo появится сообщение о том что связь установлена или сообщение обшибке.
  Click Connect. An attempt will be made to establish communication with the scope. A message will appear in the memo field stating that the connection has been established or an error message.
  Если соединение установлено, то теперь вы можете послылать команды управления с помощью кнопки Write. Если ожидается ответ, то нажмите Read. Отчет о выполнении выводится в окно memo. Его можно очистить кнопкой Clear.
  If the connection is established, you can now send control commands using the Write button. If a response is expected, then click Read. The progress report is displayed in the memo window. It can be cleared with the Clear button.
  Команды осциллографа можно выбрать из выпадающего списка или ввести самому в соответствии с SCPI для данного прибора.
  The oscilloscope commands can be selected from the drop-down list or entered yourself according to the SCPI for this device.
  .
