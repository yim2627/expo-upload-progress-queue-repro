import Constants from 'expo-constants';
import { StatusBar } from 'expo-status-bar';
import { useCallback, useEffect, useState } from 'react';
import { Button, StyleSheet, Text, View } from 'react-native';

import UploadQueueProbe from './modules/upload-queue-probe';

// Any URL that accepts a POST works. The dev server keeps the repro offline.
const probeUrl = `http://${Constants.expoConfig?.hostUri}/upload-queue-probe`;

export default function App() {
  const [result, setResult] = useState('Sending POST…');

  const sendPost = useCallback(async () => {
    setResult('Sending POST…');
    try {
      const response = await UploadQueueProbe.post(probeUrl);
      setResult(JSON.stringify(response, null, 2));
    } catch (error) {
      setResult(String(error));
    }
  }, []);

  useEffect(() => {
    sendPost();
  }, [sendPost]);

  return (
    <View style={styles.container}>
      <Text style={styles.label}>POST {probeUrl}</Text>
      <Text testID="result" style={styles.result}>
        {result}
      </Text>
      <Button title="Send POST again" onPress={sendPost} />
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    gap: 16,
  },
  label: {
    fontSize: 12,
    color: '#666',
  },
  result: {
    fontFamily: 'Menlo',
    fontSize: 14,
  },
});
